/// 🌐 WebSocket Service for Real-time Updates
/// Handles Socket.IO connections and real-time data synchronization

const jwt = require('jsonwebtoken');
const User = require('../models/User');

class WebSocketService {
    constructor(io) {
        this.io = io;
        this.connectedUsers = new Map(); // userId -> socketId
        this.userSockets = new Map(); // socketId -> userId

        this.initializeSocketHandlers();
        console.log('🔌 WebSocket service initialized');
    }

    initializeSocketHandlers() {
        this.io.on('connection', (socket) => {
            console.log(`🔌 New WebSocket connection: ${socket.id}`);

            // Handle authentication
            socket.on('authenticate', async (data) => {
                try {
                    const { token } = data;
                    if (!token) {
                        socket.emit('auth_error', { message: 'No token provided' });
                        return;
                    }

                    // Verify JWT token
                    const decoded = jwt.verify(token, process.env.JWT_SECRET);
                    const user = await User.findById(decoded.id);

                    if (!user) {
                        socket.emit('auth_error', { message: 'User not found' });
                        return;
                    }

                    // Store user connection
                    this.connectedUsers.set(user._id.toString(), socket.id);
                    this.userSockets.set(socket.id, user._id.toString());

                    // Join user-specific room
                    socket.join(`user_${user._id}`);
                    socket.join(`role_${user.role}`);

                    socket.emit('authenticated', {
                        user: {
                            id: user._id,
                            name: user.name,
                            email: user.email,
                            role: user.role
                        }
                    });

                    console.log(`✅ User ${user.name} authenticated via WebSocket`);

                } catch (error) {
                    console.error('WebSocket authentication error:', error);
                    socket.emit('auth_error', { message: 'Authentication failed' });
                }
            });

            // Handle disconnection
            socket.on('disconnect', () => {
                const userId = this.userSockets.get(socket.id);
                if (userId) {
                    this.connectedUsers.delete(userId);
                    this.userSockets.delete(socket.id);
                    console.log(`🔌 User ${userId} disconnected`);
                }
            });

            // Handle ping for connection health
            socket.on('ping', () => {
                socket.emit('pong');
            });
        });
    }

    // Send real-time updates to specific users
    notifyUser(userId, event, data) {
        const socketId = this.connectedUsers.get(userId.toString());
        if (socketId) {
            this.io.to(socketId).emit(event, data);
            return true;
        }
        return false;
    }

    // Send updates to all users with specific role
    notifyRole(role, event, data) {
        this.io.to(`role_${role}`).emit(event, data);
    }

    // Send updates to all connected users
    notifyAll(event, data) {
        this.io.emit(event, data);
    }

    // Data change notifications
    notifyDataChange(collection, operation, data, affectedUsers = []) {
        const eventData = {
            collection,
            operation,
            data,
            timestamp: new Date().toISOString()
        };

        // Notify affected users
        if (affectedUsers.length > 0) {
            affectedUsers.forEach(userId => {
                this.notifyUser(userId, 'data_changed', eventData);
            });
        }

        // Notify admins for system-wide changes
        if (['users', 'products', 'categories', 'orders'].includes(collection)) {
            this.notifyRole('admin', 'data_changed', eventData);
        }

        // Notify suppliers for relevant changes
        if (['products', 'orders', 'rfq'].includes(collection)) {
            this.notifyRole('supplier', 'data_changed', eventData);
        }

        // Notify customers for relevant changes
        if (['products', 'categories', 'orders', 'cart', 'wishlist'].includes(collection)) {
            this.notifyRole('customer', 'data_changed', eventData);
        }
    }

    // User-specific notifications
    notifyUserDataChange(userId, collection, operation, data) {
        this.notifyUser(userId, 'user_data_changed', {
            collection,
            operation,
            data,
            timestamp: new Date().toISOString()
        });
    }

    // Order status updates
    notifyOrderUpdate(orderId, status, orderData, customerId, supplierId = null) {
        const eventData = {
            orderId,
            status,
            order: orderData,
            timestamp: new Date().toISOString()
        };

        // Notify customer
        this.notifyUser(customerId, 'order_updated', eventData);

        // Notify supplier if provided
        if (supplierId) {
            this.notifyUser(supplierId, 'order_updated', eventData);
        }

        // Notify admins
        this.notifyRole('admin', 'order_updated', eventData);
    }

    // Product updates
    notifyProductUpdate(productId, operation, productData, supplierId = null) {
        const eventData = {
            productId,
            operation,
            product: productData,
            timestamp: new Date().toISOString()
        };

        // Notify supplier
        if (supplierId) {
            this.notifyUser(supplierId, 'product_updated', eventData);
        }

        // Notify all customers (for product changes)
        this.notifyRole('customer', 'product_updated', eventData);

        // Notify admins
        this.notifyRole('admin', 'product_updated', eventData);
    }

    // Message notifications
    notifyNewMessage(conversationId, messageData, participants) {
        const eventData = {
            conversationId,
            message: messageData,
            timestamp: new Date().toISOString()
        };

        // Notify all participants
        participants.forEach(userId => {
            this.notifyUser(userId, 'new_message', eventData);
        });
    }

    // Get connected users count
    getConnectedUsersCount() {
        return this.connectedUsers.size;
    }

    // Get connected users list (for debugging)
    getConnectedUsers() {
        return Array.from(this.connectedUsers.keys());
    }
}

module.exports = (io) => {
    return new WebSocketService(io);
};