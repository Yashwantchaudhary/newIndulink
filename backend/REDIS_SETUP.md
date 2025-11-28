# Redis Configuration for INDULINK Backend

## Installation

### Option 1: Docker (Recommended)
```bash
docker run --name indulink-redis -d -p 6379:6379 redis:alpine
```

###Option 2: Windows
Download from: https://github.com/microsoftarchive/redis/releases  
Or use: `choco install redis-64`

### Option 3: Ubuntu/Linux
```bash
sud apt update
sudo apt install redis-server
sudo systemctl start redis
```

## Environment Variables

Add to `.env`:
```env
# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=
```

## Testing Connection

```bash
redis-cli ping
# Should return: PONG
```

## Cache Strategy

### TTL (Time To Live) by Endpoint:
- **Products List**: 5 minutes (300s)
- **Product Details**: 10 minutes (600s)
- **User Profile**: 15 minutes (900s)
- **Dashboard Stats**: 2 minutes (120s)
- **Categories**: 30 minutes (1800s)

### Cache Invalidation:
- Product update → Invalidate product cache
- Order placement → Invalidate user + product cache
- User profile update → Invalidate user cache

## Performance Metrics

Expected improvements:
- **API Response Time**: 200ms → 50ms (75% faster)
- **Database Load**: Reduced by 60-80%
- **Concurrent Users**: 100 → 500+ users

## Monitoring

Check cache stats:
```javascript
GET /api/cache/stats
```

Clear all cache (admin only):
```javascript
POST /api/cache/clear
```
