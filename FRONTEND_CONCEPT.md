# Chatbot Frontend Concept Document

## Overview

This document outlines the concept for two frontend solutions for the chatbot API:

1. **WordPress Plugin** - For WooCommerce shop integration
2. **Standalone Web Interface** - Docker container for direct API access

Both solutions will communicate with the existing FastAPI chatbot at `https://chatbot.k8s-demo.de` (or internally via Docker network).

---

## 1. WordPress Plugin

### 1.1 Plugin Overview

**Plugin Name:** WooCommerce Chatbot Assistant
**Purpose:** Provide a floating chat widget on WooCommerce shop pages
**Compatibility:** WordPress 5.0+, WooCommerce 5.0+, PHP 7.4+

### 1.2 Features

- Floating chat widget (bottom-right corner)
- Configurable appearance (colors, position, size)
- Admin settings page for API configuration
- WooCommerce-specific system prompts (product help, order inquiries)
- Conversation history within session
- Responsive design (mobile-friendly)
- Optional: Show on specific pages only

### 1.3 Architecture

```
┌─────────────────────┐
│   WordPress Site    │
│  ┌───────────────┐  │
│  │  Chat Widget  │  │
│  │  (JS + CSS)   │  │
│  └───────┬───────┘  │
│          │          │
│  ┌───────▼───────┐  │
│  │  AJAX Handler │  │
│  │  (PHP)        │  │
│  └───────┬───────┘  │
└──────────┼──────────┘
           │ HTTPS
           ▼
┌─────────────────────┐
│  Chatbot API        │
│  chatbot.k8s-demo.de│
└─────────────────────┘
```

### 1.4 File Structure

```
woocommerce-chatbot-assistant/
├── woocommerce-chatbot-assistant.php   # Main plugin file
├── includes/
│   ├── class-admin-settings.php        # Admin settings page
│   ├── class-ajax-handler.php          # API communication
│   └── class-frontend.php              # Widget rendering
├── assets/
│   ├── css/
│   │   ├── chatbot-widget.css          # Widget styles
│   │   └── admin-settings.css          # Admin styles
│   └── js/
│       └── chatbot-widget.js           # Widget functionality
├── templates/
│   └── chat-widget.php                 # Widget HTML template
└── readme.txt                          # WordPress plugin readme
```

### 1.5 Admin Settings

| Setting | Type | Description |
|---------|------|-------------|
| API URL | Text | Chatbot API endpoint URL |
| API Username | Text | Basic Auth username |
| API Password | Password | Basic Auth password |
| System Prompt | Textarea | Custom prompt for WooCommerce context |
| Widget Title | Text | Chat widget header text |
| Primary Color | Color Picker | Main theme color |
| Widget Position | Select | bottom-right, bottom-left |
| Show on Pages | Multi-select | All pages, Shop only, Product pages only |
| Welcome Message | Text | Initial greeting message |

### 1.6 Frontend Widget Design

```
┌─────────────────────────┐
│ 🛒 Shop Assistant    ─  │  ← Header with title & minimize
├─────────────────────────┤
│                         │
│  Bot: Hello! How can    │
│  I help you today?      │
│                         │
│            You: Hi!  ←──┼── User messages right-aligned
│                         │
│  Bot: I'm here to help  │
│  with product questions │
│  and orders.            │
│                         │
├─────────────────────────┤
│ Type your message...    │  ← Input field
│                    [➤]  │  ← Send button
└─────────────────────────┘
```

### 1.7 JavaScript Flow

1. User opens chat widget (click on floating button)
2. Widget displays welcome message
3. User types message and clicks send
4. JavaScript sends AJAX request to WordPress
5. PHP handler forwards request to Chatbot API with Basic Auth
6. Response returned and displayed in chat window
7. Conversation stored in browser session storage

### 1.8 Security Considerations

- API credentials stored in WordPress options (encrypted)
- Nonce verification for AJAX requests
- Input sanitization on both client and server
- Rate limiting (optional)
- No direct API exposure to frontend (proxied through WordPress)

### 1.9 WooCommerce-Specific System Prompt Example

```
You are a helpful shop assistant for an online store. You can help customers with:
- Product information and recommendations
- Order status inquiries
- Shipping and return policies
- General shopping questions

Be friendly, concise, and helpful. If you don't know something specific about the store,
suggest the customer contact support directly.
```

---

## 2. Standalone Web Interface (Docker)

### 2.1 Overview

**Purpose:** A lightweight web interface that runs alongside the chatbot API in Docker
**Technology:** HTML/CSS/JavaScript (no build step) or lightweight framework
**Communication:** Internal Docker network (faster, no external HTTPS overhead)

### 2.2 Architecture

```
┌─────────────────────────────────────────────┐
│              Docker Network                  │
│                                             │
│  ┌─────────────┐      ┌─────────────────┐   │
│  │   caddy     │      │    fastapi      │   │
│  │   :80/:443  │─────▶│    :8000        │   │
│  └──────┬──────┘      └────────▲────────┘   │
│         │                      │            │
│         │              ┌───────┴────────┐   │
│         │              │ Internal API   │   │
│         │              │ http://fastapi │   │
│         │              │ :8000/chat     │   │
│         │              └───────▲────────┘   │
│         │                      │            │
│  ┌──────▼──────┐      ┌────────┴────────┐   │
│  │  chat-ui    │─────▶│  chat-ui        │   │
│  │  (public)   │      │  (backend)      │   │
│  │  :3000      │      │  proxies to API │   │
│  └─────────────┘      └─────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘

External Access:
- https://chatbot.k8s-demo.de → API (existing)
- https://chat.k8s-demo.de → Web UI (new)
```

### 2.3 Technology Options

#### Option A: Static HTML + Vanilla JS (Recommended)

**Pros:**
- No build step required
- Minimal Docker image size (~5MB with nginx)
- Fast loading
- Easy to maintain

**Cons:**
- Limited interactivity without frameworks

#### Option B: Lightweight Framework (Alpine.js or Petite-Vue)

**Pros:**
- Reactive UI with minimal overhead
- Still no build step required
- Better state management

**Cons:**
- Additional dependency

#### Option C: Full SPA (React/Vue/Svelte)

**Pros:**
- Rich interactivity
- Component-based architecture

**Cons:**
- Requires build step
- Larger bundle size
- More complex deployment

**Recommendation:** Option A (Static HTML + Vanilla JS) or Option B (Alpine.js) for simplicity and performance.

### 2.4 File Structure

```
chat-ui/
├── Dockerfile
├── nginx.conf
├── public/
│   ├── index.html
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── chat.js
└── README.md
```

### 2.5 Docker Configuration

#### Dockerfile

```dockerfile
FROM nginx:alpine

# Copy static files
COPY public/ /usr/share/nginx/html/

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]
```

#### nginx.conf

```nginx
server {
    listen 3000;
    server_name localhost;

    root /usr/share/nginx/html;
    index index.html;

    # Serve static files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy API requests to FastAPI container
    location /api/ {
        proxy_pass http://fastapi:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Authorization $http_authorization;
        proxy_read_timeout 120s;
    }
}
```

### 2.6 docker-compose.yml Updates

```yaml
services:
  # ... existing services ...

  chat-ui:
    build:
      context: ./chat-ui
      dockerfile: Dockerfile
    container_name: chat-ui
    restart: unless-stopped
    networks:
      - chatbot-network
    depends_on:
      fastapi:
        condition: service_healthy

  caddy:
    # Update Caddyfile to route chat subdomain
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
```

### 2.7 Caddyfile Updates

```caddyfile
chatbot.k8s-demo.de {
    reverse_proxy fastapi:8000
}

chat.k8s-demo.de {
    reverse_proxy chat-ui:3000
}
```

### 2.8 Web Interface Design

```html
┌─────────────────────────────────────────────┐
│            Chatbot Assistant                │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │                                     │    │
│  │   Chat messages appear here         │    │
│  │                                     │    │
│  │   [Bot]: Hello! How can I help?     │    │
│  │                                     │    │
│  │                    [You]: Hi there  │    │
│  │                                     │    │
│  │   [Bot]: I'm happy to assist...     │    │
│  │                                     │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  ┌─────────────────────────────────┐ ┌───┐  │
│  │ Type your message...            │ │ ➤ │  │
│  └─────────────────────────────────┘ └───┘  │
│                                             │
│  Powered by Ollama • Status: 🟢 Online      │
└─────────────────────────────────────────────┘
```

### 2.9 JavaScript Implementation Outline

```javascript
// chat.js
const Chat = {
    messages: [],

    async sendMessage(message) {
        // Add user message to UI
        this.addMessage('user', message);

        // Show typing indicator
        this.showTyping();

        try {
            // Send to local API proxy
            const response = await fetch('/api/chat', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Basic ' + btoa('username:password')
                },
                body: JSON.stringify({
                    message: message,
                    system_prompt: 'You are a helpful assistant.'
                })
            });

            const data = await response.json();

            // Add bot response to UI
            this.addMessage('bot', data.response);

        } catch (error) {
            this.addMessage('error', 'Failed to get response');
        }

        this.hideTyping();
    },

    addMessage(type, content) {
        // Append message to chat container
    },

    showTyping() {
        // Show typing indicator
    },

    hideTyping() {
        // Hide typing indicator
    }
};
```

### 2.10 Features

- Clean, modern UI
- Real-time health status indicator
- Conversation history (session-based)
- Responsive design
- Keyboard shortcuts (Enter to send)
- Loading/typing indicators
- Error handling with retry
- Optional: Dark mode toggle
- Optional: Export conversation

### 2.11 Authentication Options

#### Option A: Hardcoded (Development)
- Credentials in JavaScript (not secure for production)

#### Option B: Environment Variables
- Pass credentials via Docker environment
- Inject into HTML template at build time

#### Option C: Login Form
- User enters credentials
- Stored in session storage
- More secure for multi-user scenarios

**Recommendation:** Option B for single-user deployment, Option C for public access.

### 2.12 Benefits of Docker Web UI

| Benefit | Description |
|---------|-------------|
| Internal Communication | Uses Docker network, no external DNS resolution |
| Lower Latency | Direct container-to-container communication |
| Simplified Auth | Can use internal network security |
| Easy Deployment | Same docker-compose deployment |
| Isolated | Separate from main website concerns |

---

## 3. Comparison

| Feature | WordPress Plugin | Docker Web UI |
|---------|-----------------|---------------|
| Target Users | WooCommerce customers | Direct chatbot users |
| Integration | Embedded in shop | Standalone page |
| Deployment | WordPress plugin install | Docker container |
| API Access | External HTTPS | Internal Docker network |
| Customization | Admin settings page | Environment variables |
| Authentication | Proxied through WP | Direct or login form |
| Use Case | Customer support widget | Admin/testing interface |

---

## 4. Development Effort Estimates

### 4.1 General WordPress Plugin Complexity Levels

| Complexity | Description | Typical Effort |
|------------|-------------|----------------|
| **Simple** | Single function, no admin UI, no database | 1-2 days |
| **Moderate** | Admin settings, AJAX, custom CSS/JS | 3-7 days |
| **Complex** | Database tables, REST API, multiple integrations | 1-3 weeks |

### 4.2 WordPress Chat Plugin Breakdown

The chat plugin falls into **moderate complexity** (3-5 days total):

| Component | Effort | Notes |
|-----------|--------|-------|
| Main plugin file + hooks | 2-3 hours | Standard boilerplate |
| Admin settings page | 4-6 hours | WordPress Settings API is verbose |
| AJAX handler (API proxy) | 2-3 hours | Straightforward HTTP forwarding |
| Frontend widget (JS) | 6-8 hours | Message handling, UI state, async calls |
| CSS styling | 3-4 hours | Responsive, theme-compatible |
| Testing & debugging | 4-6 hours | Cross-browser, WordPress versions |

**Total: 3-5 days**

### 4.3 Docker Web UI Breakdown

The standalone web interface is **simpler** (1-2 days total):

| Component | Effort | Notes |
|-----------|--------|-------|
| HTML structure | 1-2 hours | Single page layout |
| CSS styling | 2-3 hours | Can reuse for WordPress plugin later |
| JavaScript chat logic | 4-6 hours | Fetch API, DOM manipulation |
| Dockerfile + nginx config | 1-2 hours | Standard setup |
| docker-compose integration | 1 hour | Add service, update Caddy |
| Testing | 2-3 hours | API communication, UI flow |

**Total: 1-2 days**

### 4.4 Main Development Challenges

#### WordPress Plugin
- **Settings API** - Verbose and unintuitive compared to modern frameworks
- **JavaScript without build tools** - WordPress traditionally uses jQuery
- **CSS conflicts** - Must scope styles to avoid theme interference
- **Security requirements** - Nonces, sanitization, capability checks mandatory
- **Compatibility testing** - Multiple WordPress/WooCommerce versions

#### Docker Web UI
- **Authentication handling** - Deciding how to manage credentials
- **Error handling** - Network failures, API timeouts
- **Cross-browser compatibility** - Vanilla JS requires more testing

### 4.5 What Makes This Project Easier

- API already has CORS enabled (allows browser requests)
- Simple REST endpoint (just POST /chat)
- No database tables needed in WordPress (conversations stored server-side)
- Basic Auth is straightforward to proxy
- Can reuse CSS/JS between both frontends

### 4.6 Alternative: Existing Solutions

Before building custom, consider existing options:

| Option | Pros | Cons |
|--------|------|------|
| **Tidio/Crisp/Tawk.to** | Ready-made, feature-rich | Third-party, monthly cost, no custom LLM |
| **WPBot** | WordPress native | Limited AI, yearly license |
| **Custom (this approach)** | Full control, your LLM | Development effort |

**Verdict:** Custom development is justified since you need integration with your own Ollama-based LLM.

### 4.7 Recommended Approach

1. **Start with Docker Web UI first** (1-2 days)
   - Validates the chat UX quickly
   - No WordPress complexity
   - Immediate results
   - CSS/JS can be reused

2. **Then build WordPress plugin** (3-5 days)
   - Reuse the JS/CSS from web UI
   - Proven chat interface
   - Focus only on WordPress integration

**Combined total: 4-7 days**

---

## 5. Implementation Priority

### Phase 1: Docker Web UI
1. Create basic HTML/CSS/JS interface
2. Add to docker-compose.yml
3. Configure Caddy routing
4. Test internal API communication

### Phase 2: WordPress Plugin
1. Create plugin structure
2. Implement admin settings
3. Build chat widget
4. Test with WooCommerce

### Phase 3: Enhancements
1. Conversation persistence (database)
2. Analytics/logging
3. Multiple system prompts
4. User feedback collection

---

## 6. Next Steps

1. **Review this concept** - Confirm requirements and preferences
2. **Choose technology** - Decide on web UI framework approach
3. **Design approval** - Finalize UI/UX design
4. **Implementation** - Build both frontends
5. **Testing** - Verify functionality and performance
6. **Deployment** - Deploy to production

---

## 7. Questions to Clarify

1. Should the web UI require login or be publicly accessible?
2. Any specific branding/colors for the chat interfaces?
3. Should conversation history persist across sessions?
4. Any specific WooCommerce features to integrate (product search, order lookup)?
5. Preferred subdomain for web UI (e.g., chat.k8s-demo.de)?
