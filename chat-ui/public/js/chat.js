const Chat = {
    messagesContainer: null,
    form: null,
    input: null,
    sendButton: null,
    statusElement: null,
    isLoading: false,

    init() {
        this.messagesContainer = document.getElementById('messages');
        this.form = document.getElementById('chat-form');
        this.input = document.getElementById('message-input');
        this.sendButton = document.getElementById('send-button');
        this.statusElement = document.getElementById('status');

        this.form.addEventListener('submit', (e) => this.handleSubmit(e));
        this.input.addEventListener('keydown', (e) => this.handleKeydown(e));

        // Check API health on load
        this.checkHealth();
    },

    async checkHealth() {
        try {
            const response = await fetch('/api/health');
            const data = await response.json();

            if (data.status === 'healthy') {
                this.setStatus('online', 'Online');
            } else {
                this.setStatus('offline', 'Degraded');
            }
        } catch (error) {
            this.setStatus('offline', 'Offline');
        }
    },

    setStatus(status, text) {
        this.statusElement.className = `status ${status}`;
        this.statusElement.querySelector('.status-text').textContent = text;
    },

    handleKeydown(e) {
        // Submit on Enter (without Shift)
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            this.form.dispatchEvent(new Event('submit'));
        }
    },

    async handleSubmit(e) {
        e.preventDefault();

        const message = this.input.value.trim();
        if (!message || this.isLoading) return;

        // Clear input
        this.input.value = '';

        // Add user message
        this.addMessage('user', message);

        // Show typing indicator
        this.showTyping();

        // Disable input while loading
        this.setLoading(true);

        try {
            const response = await this.sendMessage(message);
            this.addMessage('bot', response);
        } catch (error) {
            this.addMessage('error', error.message || 'Failed to get response. Please try again.');
        }

        // Hide typing and re-enable input
        this.hideTyping();
        this.setLoading(false);

        // Focus input
        this.input.focus();
    },

    async sendMessage(message) {
        const response = await fetch('/api/chat', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                message: message,
                system_prompt: 'You are a helpful assistant.'
            })
        });

        if (!response.ok) {
            if (response.status === 401) {
                throw new Error('Authentication failed. Please check credentials.');
            } else if (response.status === 504) {
                throw new Error('Request timed out. Please try again.');
            } else {
                throw new Error(`Server error: ${response.status}`);
            }
        }

        const data = await response.json();
        return data.response;
    },

    addMessage(type, content) {
        const messageDiv = document.createElement('div');
        messageDiv.className = `message ${type}`;

        const contentDiv = document.createElement('div');
        contentDiv.className = 'message-content';
        contentDiv.textContent = content;

        messageDiv.appendChild(contentDiv);
        this.messagesContainer.appendChild(messageDiv);

        // Scroll to bottom
        this.scrollToBottom();
    },

    showTyping() {
        const typingDiv = document.createElement('div');
        typingDiv.className = 'typing-indicator';
        typingDiv.id = 'typing-indicator';
        typingDiv.innerHTML = '<span></span><span></span><span></span>';
        this.messagesContainer.appendChild(typingDiv);
        this.scrollToBottom();
    },

    hideTyping() {
        const typingIndicator = document.getElementById('typing-indicator');
        if (typingIndicator) {
            typingIndicator.remove();
        }
    },

    setLoading(loading) {
        this.isLoading = loading;
        this.input.disabled = loading;
        this.sendButton.disabled = loading;
    },

    scrollToBottom() {
        this.messagesContainer.scrollTop = this.messagesContainer.scrollHeight;
    }
};

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => Chat.init());
