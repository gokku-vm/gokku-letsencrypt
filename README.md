# Let's Encrypt Plugin for Gokku

This plugin provides automatic SSL certificate management using Let's Encrypt for your Gokku applications.

## Features

- **Global Plugin Architecture**: Install once, use everywhere
- **Automatic Certificate Generation**: Create SSL certificates for your domains
- **Nginx Integration**: Automatic SSL configuration for nginx services
- **Auto-renewal Enabled by Default**: Set it and forget it - certificates renew automatically
- **Persistent Storage**: Certificates are stored persistently with local sync
- **Multiple Domains**: Support for unlimited domains

## Installation

```bash
# Install the Let's Encrypt plugin (run once, auto-renewal enabled by default)
gokku letsencrypt:install

# Create certificates for your domains
gokku letsencrypt:create example.com contact@example.com
gokku letsencrypt:create api.example.com

# Link to nginx service
gokku letsencrypt:link-nginx nginx-lb
```

## Commands

### Plugin Management
- `gokku letsencrypt:install` - Install Let's Encrypt plugin (auto-renewal enabled by default)
- `gokku letsencrypt:uninstall` - Uninstall Let's Encrypt plugin
- `gokku letsencrypt:status` - Show plugin status

### Certificate Management
- `gokku letsencrypt:create <domain> [email]` - Create SSL certificate
- `gokku letsencrypt:renew` - Renew all certificates
- `gokku letsencrypt:list` - List all certificates
- `gokku letsencrypt:info <domain>` - Show certificate information
- `gokku letsencrypt:logs` - Show certificate logs

### Nginx Integration
- `gokku letsencrypt:link-nginx <nginx-service>` - Link to nginx service
- `gokku letsencrypt:unlink-nginx <nginx-service>` - Unlink from nginx service

### Automation
- `gokku letsencrypt:auto-renew` - Setup auto-renewal
- `gokku letsencrypt:remove-auto-renew` - Remove auto-renewal

## Configuration

### Plugin Directory Structure
```
/opt/gokku/plugins/letsencrypt/
├── certs/                    # SSL certificates (global)
│   └── <domain>/             # Domain-specific certificates
│       ├── fullchain.pem     # Full certificate chain
│       └── privkey.pem       # Private key
├── accounts/                 # Let's Encrypt accounts
├── logs/                     # Certificate logs
├── config.json               # Gokku plugin configuration
├── plugin.conf               # Internal plugin configuration
└── renew-certificates.sh     # Renewal script
```

### Nginx Integration
When linked to nginx, the plugin automatically:
- Creates SSL server blocks for HTTPS
- Sets up HTTP to HTTPS redirects
- Links certificates to nginx SSL directory
- Configures security headers

### Auto-renewal
The plugin automatically sets up a scheduled job during installation that runs daily at 2:30 AM to check and renew certificates that are expiring within 30 days. No additional configuration needed!

**Note**: During certificate renewal, the plugin temporarily stops containers using port 80 for a few seconds (HTTPS traffic on port 443 remains unaffected). This happens automatically at 2:30 AM and only when certificates actually need renewal (within 30 days of expiry).

## Examples

### Basic Setup
```bash
# Create certificate
gokku letsencrypt:create example.com contact@example.com

# Link to nginx
gokku letsencrypt:link-nginx nginx-lb
```

### Multiple Domains
```bash
# Create certificates for multiple domains
gokku letsencrypt:create api.example.com
gokku letsencrypt:create app.example.com
gokku letsencrypt:create admin.example.com

# List all certificates
gokku letsencrypt:list
```

### Certificate Management
```bash
# Check certificate status
gokku letsencrypt:info example.com

# Renew all certificates
gokku letsencrypt:renew

# Check plugin status
gokku letsencrypt:status
```

## Real-World Use Case: Multi-Service Application with HTTPS

This example demonstrates how to use `gokku-letsencrypt` together with `gokku-nginx` to deploy a production-ready multi-service application with automatic SSL certificate management.

### Scenario

You have a multi-service application consisting of:
- **Frontend Application** (React/Vue/Angular)
- **Backend API** (Node.js/Python/Ruby)
- **Admin Panel** (Dashboard application)
- **API Gateway** (Routing service)

All services need to run under a single domain with automatic HTTPS enabled.

### Step-by-Step Setup

#### 1. Install and Configure gokku-nginx

```bash
# Install nginx plugin
gokku plugin:add nginx

# Create nginx service for load balancing
gokku services:create nginx --name nginx-lb

# Add applications and configure routing
gokku nginx:add-domain nginx-lb frontend-app myapp.com
gokku nginx:add-domain nginx-lb api-backend api.myapp.com
gokku nginx:add-domain nginx-lb admin-panel admin.myapp.com
```

#### 2. Install and Configure gokku-letsencrypt

```bash
gokku plugin:add letsencrypt

# Create SSL certificates for all domains
gokku letsencrypt:create myapp.com admin@myapp.com
gokku letsencrypt:create api.myapp.com
gokku letsencrypt:create admin.myapp.com

# Link certificates to nginx service
gokku letsencrypt:link-nginx nginx-lb
```

#### 3. Automatic Integration Result

After linking, `gokku-letsencrypt` automatically:

- Creates certificate symlinks in `/opt/gokku/services/nginx-lb/ssl/`
- Makes certificates available to nginx for each domain:
  - `myapp.com.crt` / `myapp.com.key`
  - `api.myapp.com.crt` / `api.myapp.com.key`
  - `admin.myapp.com.crt` / `admin.myapp.com.key`
- Configures HTTPS server blocks in nginx
- Sets up HTTP to HTTPS redirects
- Applies security headers

#### 4. Complete Deployment Flow

```bash
# Complete setup for a new application

# 1. Install plugins (one time only)
gokku plugin:add letsencrypt
gokku plugin:add nginx

# 2. Create nginx service
gokku services:create nginx --name production-lb
gokku letsencrypt:link-nginx production-lb

# 3. Deploy applications
gokku deploy frontend-app
gokku deploy api-backend
gokku deploy admin-panel

# 4. Configure nginx routing
gokku nginx:add-domain production-lb frontend-app example.com
gokku nginx:add-domain production-lb api-backend api.example.com
gokku nginx:add-domain production-lb admin-panel admin.example.com

# 5. Add SSL (certificates created and linked automatically)
gokku letsencrypt:create example.com contact@example.com
gokku letsencrypt:create api.example.com
gokku letsencrypt:create admin.example.com

# Done! Application running with automatic HTTPS
```

#### 5. Verification and Maintenance

```bash
# Verify certificate status
gokku letsencrypt:list
gokku letsencrypt:info myapp.com

# Verify nginx configuration
gokku nginx:test nginx-lb

# Manually renew certificates if needed
gokku letsencrypt:renew

# View certificate logs
gokku letsencrypt:logs
```

### Architecture Diagram

```
Internet Request
    ↓
[Port 443 HTTPS] ← Let's Encrypt Certificate (gokku-letsencrypt)
    ↓
[Nginx Load Balancer] ← gokku-nginx
    ↓
┌─────────────────┬─────────────────┬─────────────────┐
│  Frontend App   │   API Backend   │   Admin Panel   │
│  (myapp.com)    │ (api.myapp.com) │ (admin.myapp...)│
└─────────────────┴─────────────────┴─────────────────┘
```

### Integration Benefits

1. **Automation**: Certificates are automatically created and renewed
2. **Seamless Integration**: Certificates automatically linked to nginx configuration
3. **Security by Default**: HTTPS enabled with automatic HTTP to HTTPS redirects
4. **Multi-Domain Support**: Multiple domains configured with a single command each
5. **Zero Maintenance**: Automatic daily renewal checks for expiring certificates

## Requirements

- Docker (for certbot container)
- Nginx service (for SSL configuration)
- Valid domain pointing to your server
- Ports 80 and 443 accessible from the internet

### Network Requirements

**IMPORTANT**: The Let's Encrypt validation requires external internet access to your server on port 80. Make sure:
- Port 80 is open in your firewall (ufw/iptables)
- If using AWS EC2: Port 80 is open in your security group for inbound HTTP traffic from `0.0.0.0/0`
- If using other cloud providers: Ensure port 80 allows inbound traffic
- DNS properly resolves your domain to the server's public IP

## Troubleshooting

### Certificate Creation Fails
- Ensure domain points to your server
- Check that ports 80 and 443 are accessible from the internet
  - **AWS EC2**: Open ports 80 and 443 in your security group
  - **Firewall**: Ensure ufw/iptables allow inbound traffic on ports 80/443
  - Test with: `curl -I http://your-domain.com`
- Verify email address is valid
- Check logs: `gokku letsencrypt:logs`

### Nginx Integration Issues
- Ensure nginx service is running
- Check nginx configuration: `gokku nginx:test nginx-lb`
- Verify SSL files are linked: `ls -la /opt/gokku/services/nginx-lb/ssl/`

### Auto-renewal Not Working
- Check scheduled job: `cat /etc/cron.d/gokku-letsencrypt`
- Test renewal script: `/opt/gokku/plugins/letsencrypt/renew-certificates.sh`
- Check renewal logs: `tail -f /var/log/gokku-letsencrypt.log`

## Security Notes

- Certificates are stored in `/opt/gokku/plugins/letsencrypt/certs/`
- Private keys are protected with appropriate permissions
- Auto-renewal runs as root via scheduled job
- SSL configurations include security headers
- Plugin is global - accessible by all services

## Support

For issues and feature requests, please visit the [Gokku Let's Encrypt Plugin repository](https://github.com/thadeu/gokku-letsencrypt).
