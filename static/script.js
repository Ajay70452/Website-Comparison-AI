document.addEventListener('DOMContentLoaded', () => {
    const form = document.getElementById('url-form');
    const submitButton = document.getElementById('submit-button');
    const loadingIndicator = document.getElementById('loading-indicator');
    const resultsContent = document.getElementById('results-content');

    form.addEventListener('submit', async (event) => {
        event.preventDefault();

        // Get form data
        const urlA = document.getElementById('url_a').value;
        const urlB = document.getElementById('url_b').value;

        // UI updates for loading state
        submitButton.disabled = true;
        loadingIndicator.style.display = 'block';
        resultsContent.textContent = 'Analysis in progress...';

        try {
            const response = await fetch('/analyze', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    url_a: urlA,
                    url_b: urlB,
                }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.detail || 'An unknown error occurred.');
            }

            const data = await response.json();
            resultsContent.textContent = data.analysis;

        } catch (error) {
            resultsContent.textContent = `Error: ${error.message}`;
        } finally {
            // UI updates to end loading state
            submitButton.disabled = false;
            loadingIndicator.style.display = 'none';
        }
    });
});