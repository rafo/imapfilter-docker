# imapfilter Docker Image

A lightweight, flexible Docker image for [imapfilter](https://github.com/lefcha/imapfilter) - a mail filtering utility that processes mailboxes according to Lua scripts.

## Features

- **Lightweight**: Multi-stage Alpine-based build (~20MB final image)
- **Secure**: Runs as non-root user
- **Flexible**: Supports daemon mode or one-shot execution
- **Multi-architecture**: Supports amd64, arm64, and arm/v7 (perfect for Synology NAS, Raspberry Pi, etc.)
- **Configurable**: Easy configuration via environment variables and volume mounts
- **Health checks**: Built-in container health monitoring
- **Automated builds**: GitHub Actions automatically builds and publishes images

## Quick Start

### Using Docker Compose (Recommended)

1. Create a `docker-compose.yml` file:

```yaml
services:
  imapfilter:
    image: ghcr.io/YOUR_GITHUB_USERNAME/imapfilter:latest
    container_name: imapfilter
    restart: unless-stopped
    environment:
      - RUN_MODE=daemon
      - RUN_INTERVAL=900
      - TZ=Europe/Berlin
    volumes:
      - ./config.lua:/config/config.lua:ro
```

2. Create your `config.lua` (see [examples](#configuration-examples))

3. Start the container:

```bash
docker compose up -d
```

### Using Docker CLI

```bash
docker run -d \
  --name imapfilter \
  --restart unless-stopped \
  -e RUN_MODE=daemon \
  -e RUN_INTERVAL=900 \
  -e TZ=Europe/Berlin \
  -v $(pwd)/config.lua:/config/config.lua:ro \
  ghcr.io/YOUR_GITHUB_USERNAME/imapfilter:latest
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `RUN_MODE` | Execution mode: `daemon`, `once`, or custom | `daemon` |
| `RUN_INTERVAL` | Seconds between runs in daemon mode | `900` (15 min) |
| `TZ` | Timezone (e.g., `Europe/Berlin`, `America/New_York`) | `Europe/Berlin` |
| `IMAPFILTER_CONFIG` | Path to config file inside container | `/config/config.lua` |

### Run Modes

#### Daemon Mode (Continuous)
Runs imapfilter repeatedly at the specified interval:
```yaml
environment:
  - RUN_MODE=daemon
  - RUN_INTERVAL=900  # Run every 15 minutes
```

#### One-Shot Mode
Runs imapfilter once and exits:
```yaml
environment:
  - RUN_MODE=once
```

#### Custom Command
Pass custom arguments to imapfilter:
```bash
docker run -e RUN_MODE=custom \
  ghcr.io/YOUR_GITHUB_USERNAME/imapfilter:latest \
  imapfilter -c /config/config.lua -d /config/debug.log
```

## Configuration Examples

### Basic Gmail Configuration

Create a `config.lua` file:

```lua
-- Options
options.create = true
options.expunge = true
options.subscribe = true
options.timeout = 120

-- Gmail account
account = IMAP({
    server = "imap.gmail.com",
    username = "your-email@gmail.com",
    password = "your-app-password",
    port = 993,
    ssl = "tls1",
})

-- Get mailbox references
inbox = account.INBOX
inbox:check_status()

-- Example: Move newsletters to folder
newsletters = inbox:contain_from("newsletter@example.com")
    + inbox:contain_from("updates@example.com")
newsletters:move_messages(account["Newsletters"])

-- Example: Delete old spam
spam = account["[Gmail]/Spam"]:is_older(30)
spam:delete_messages()
```

### Advanced Configuration with Multiple Accounts

See the [examples](./examples) directory for more complex configurations including:
- Multiple IMAP accounts
- Mailing list detection
- Automated cleanup rules
- Custom filter functions

## Deployment

### Synology NAS

1. Install Docker from the Package Center
2. Create a folder for your configuration (e.g., `/docker/imapfilter`)
3. Upload your `config.lua` and `docker-compose.yml`
4. SSH into your Synology and run:

```bash
cd /volume1/docker/imapfilter
docker compose up -d
```

Alternatively, use the Synology Docker GUI:
1. Go to **Container Manager**
2. Create a new project from the `docker-compose.yml`
3. Adjust the volume paths to match your Synology structure

### Portainer

1. Go to **Stacks** > **Add stack**
2. Paste the docker-compose.yml content
3. Add your config.lua as a volume or use Portainer's file editor
4. Deploy the stack

### Kubernetes

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: imapfilter
spec:
  replicas: 1
  selector:
    matchLabels:
      app: imapfilter
  template:
    metadata:
      labels:
        app: imapfilter
    spec:
      containers:
      - name: imapfilter
        image: ghcr.io/YOUR_GITHUB_USERNAME/imapfilter:latest
        env:
        - name: RUN_MODE
          value: "daemon"
        - name: RUN_INTERVAL
          value: "900"
        volumeMounts:
        - name: config
          mountPath: /config/config.lua
          subPath: config.lua
      volumes:
      - name: config
        configMap:
          name: imapfilter-config
```

## Building from Source

### Local Build

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/imapfilter-docker.git
cd imapfilter-docker
docker build -t imapfilter:local .
```

### Multi-architecture Build

```bash
docker buildx build \
  --platform linux/amd64,linux/arm64,linux/arm/v7 \
  -t imapfilter:multi .
```

## Troubleshooting

### View Container Logs

```bash
docker logs -f imapfilter
```

### Check Container Status

```bash
docker ps -a | grep imapfilter
docker inspect imapfilter
```

### Test Configuration

Run in one-shot mode to test your configuration:

```bash
docker run --rm \
  -e RUN_MODE=once \
  -v $(pwd)/config.lua:/config/config.lua:ro \
  ghcr.io/YOUR_GITHUB_USERNAME/imapfilter:latest
```

### Common Issues

#### "Configuration file not found"
Make sure your volume mount is correct and the file exists:
```bash
ls -la config.lua
```

#### Permission Denied
Ensure the config file is readable:
```bash
chmod 644 config.lua
```

#### Connection Refused
- Check your IMAP server and port
- Verify firewall settings
- For Gmail, ensure you're using an App Password, not your regular password

## Security Considerations

- **Never commit credentials**: Use environment variables or secrets management
- **Use App Passwords**: For Gmail, create an app-specific password
- **Mount config read-only**: Use `:ro` flag on volume mounts
- **Regular updates**: Keep the image updated for security patches

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Resources

- [imapfilter Official Repository](https://github.com/lefcha/imapfilter)
- [imapfilter Documentation](https://github.com/lefcha/imapfilter/wiki)
- [Lua 5.4 Reference Manual](https://www.lua.org/manual/5.4/)

## Acknowledgments

- Based on [imapfilter](https://github.com/lefcha/imapfilter) by Eleftherios Chatzimparmpas
- Inspired by [Docker configuration](https://github.com/IlyaVassyutovich/imapfilter/wiki/Docker)
