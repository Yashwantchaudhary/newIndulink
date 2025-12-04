// middleware/errorHandler.js
'use strict';

const { v4: uuidv4 } = require('uuid');
const newrelic = (() => {
  try { return require('newrelic'); } catch { return null; }
})();
const Sentry = (() => {
  try { return require('@sentry/node'); } catch { return null; }
})();

/**
 * Normalize and map errors to a consistent API response.
 * Response shape:
 * {
 *   success: false,
 *   message: string,
 *   errors?: [ { field?, message } ],
 *   errorId: string,
 *   statusCode: number
 * }
 */
const errorHandler = (err, req, res, next) => {
  // Ensure we always have an object we can mutate
  const errorId = uuidv4();
  let statusCode = 500;
  let message = 'Server error';
  let errors = undefined;

  // Log full error in development
  if (process.env.NODE_ENV === 'development') {
    console.error(`[${errorId}] Error:`, err);
  }

  // Report to external monitoring (non-blocking)
  try {
    if (Sentry) Sentry.captureException(err);
  } catch (e) {
    // ignore Sentry errors
  }
  try {
    if (newrelic && typeof newrelic.noticeError === 'function') {
      newrelic.noticeError(err, { errorId, path: req.originalUrl, method: req.method });
    }
  } catch (e) {
    // ignore New Relic errors
  }

  // Handle common error types

  // Mongoose CastError (invalid ObjectId)
  if (err && err.name === 'CastError') {
    statusCode = 404;
    message = 'Resource not found';
  }

  // Mongoose duplicate key error
  else if (err && (err.code === 11000 || err.code === 11001)) {
    statusCode = 400;
    const key = err.keyValue ? Object.keys(err.keyValue)[0] : 'field';
    message = `${key} already exists`;
    errors = [{ field: key, message }];
  }

  // Mongoose validation error
  else if (err && err.name === 'ValidationError' && err.errors) {
    statusCode = 400;
    const msgs = Object.values(err.errors).map(e => e.message || String(e));
    message = msgs.join(', ');
    errors = Object.entries(err.errors).map(([field, e]) => ({ field, message: e.message || String(e) }));
  }

  // Express-validator (result.throw or validation error format)
  else if (err && err.array && typeof err.array === 'function') {
    // e.g., result.throw() from express-validator
    const extracted = err.array();
    statusCode = 400;
    message = extracted.map(e => e.msg).join(', ') || 'Validation error';
    errors = extracted.map(e => ({ field: e.param, message: e.msg }));
  }

  // Joi validation error
  else if (err && err.isJoi && err.details) {
    statusCode = 400;
    const details = err.details.map(d => d.message);
    message = details.join(', ');
    errors = err.details.map(d => ({ field: d.path.join('.'), message: d.message }));
  }

  // JSON parse error (bad JSON body)
  else if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    statusCode = 400;
    message = 'Malformed JSON body';
  }

  // Multer file upload errors
  else if (err && err.name === 'MulterError') {
    statusCode = 400;
    if (err.code === 'LIMIT_FILE_SIZE') message = 'File size too large';
    else if (err.code === 'LIMIT_UNEXPECTED_FILE') message = 'Unexpected file field';
    else message = err.message || 'File upload error';
  }

  // JWT errors
  else if (err && err.name === 'JsonWebTokenError') {
    statusCode = 401;
    message = 'Invalid token';
  } else if (err && err.name === 'TokenExpiredError') {
    statusCode = 401;
    message = 'Token expired';
  }

  // HTTP errors created by libraries (e.g., http-errors)
  else if (err && typeof err.status === 'number') {
    statusCode = err.status;
    message = err.message || message;
    if (err.errors) {
      errors = Array.isArray(err.errors) ? err.errors : [err.errors];
    }
  }

  // Fallback: use err.message if present
  else if (err && err.message) {
    message = err.message;
  }

  // Build response payload
  const payload = {
    success: false,
    message: process.env.NODE_ENV === 'production' && statusCode === 500 ? 'Server error' : message,
    errorId,
    statusCode
  };

  if (errors && Array.isArray(errors) && errors.length > 0) {
    payload.errors = errors;
  }

  // Include stack only in development
  if (process.env.NODE_ENV === 'development') {
    payload.stack = err && err.stack ? err.stack : undefined;
  }

  // Optionally include minimal request context for debugging (non-PII)
  if (process.env.NODE_ENV !== 'production') {
    payload.request = {
      method: req.method,
      path: req.originalUrl,
      params: req.params,
      query: req.query
    };
  }

  // Final log for production errors (minimal)
  if (statusCode >= 500 && process.env.NODE_ENV !== 'development') {
    console.error(`[${errorId}] Internal error:`, { message: payload.message, path: req.originalUrl, method: req.method });
  }

  return res.status(statusCode).json(payload);
};

module.exports = errorHandler;
