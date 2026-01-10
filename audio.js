// Audio Mode (TTS)
document.addEventListener('DOMContentLoaded', () => {
    // Create Audio Button
    const header = document.querySelector('header');
    if (!header) return;

    // Insert before theme toggle or after
    // Current order: Sidebar | Search | Theme. Add Audio after theme? Or before theme.
    // Let's create it dynamically if it doesn't exist in template
    let audioBtn = document.getElementById('audio-toggle');
    if (!audioBtn) {
        audioBtn = document.createElement('button');
        audioBtn.id = 'audio-toggle';
        audioBtn.textContent = '🎧'; // Headphones
        audioBtn.setAttribute('aria-label', 'Listen to Section');
        audioBtn.style.fontSize = '1.2rem';
        audioBtn.style.background = 'none';
        audioBtn.style.border = 'none';
        audioBtn.style.color = 'inherit';
        audioBtn.style.cursor = 'pointer';
        audioBtn.style.marginRight = '10px';

        const themeBtn = document.getElementById('theme-toggle');
        if (themeBtn) {
            header.insertBefore(audioBtn, themeBtn);
        } else {
            header.appendChild(audioBtn);
        }
    }

    let speaking = false;
    let utterance = null;

    audioBtn.addEventListener('click', () => {
        if (speaking) {
            window.speechSynthesis.cancel();
            speaking = false;
            audioBtn.textContent = '🎧';
            audioBtn.classList.remove('active');
        } else {
            startSpeaking();
        }
    });

    function startSpeaking() {
        const content = document.querySelector('.content-card');
        if (!content) return;

        // Clone to strip non-readable elements?
        // Just reading innerText usually works well enough
        // Exclude footnotes?
        let text = content.innerText;

        // Remove footnotes text roughly "[1]"
        // But innerText might include them.

        if ('speechSynthesis' in window) {
            utterance = new SpeechSynthesisUtterance(text);
            utterance.rate = 1.0;
            utterance.pitch = 1.0;

            // Select voice?
            // Just default for now.

            utterance.onend = () => {
                speaking = false;
                audioBtn.textContent = '🎧';
                audioBtn.classList.remove('active');
            };

            window.speechSynthesis.speak(utterance);
            speaking = true;
            audioBtn.textContent = '⏹️'; // Stop icon
            audioBtn.classList.add('active');
        } else {
            alert("Sorry, your browser doesn't support text-to-speech.");
        }
    }
});
