document.addEventListener('DOMContentLoaded', () => {
  // Navigation handling
  const navItems = document.querySelectorAll('.nav-item');
  const sections = document.querySelectorAll('.doc-section');

  function navigateTo(sectionId) {
    // Update nav active state
    navItems.forEach(item => {
      if (item.dataset.section === sectionId) {
        item.classList.add('active');
      } else {
        item.classList.remove('active');
      }
    });

    // Update section active state
    sections.forEach(sec => {
      if (sec.id === sectionId) {
        sec.classList.add('active');
      } else {
        sec.classList.remove('active');
      }
    });
  }

  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const targetId = item.dataset.section;
      navigateTo(targetId);
      window.location.hash = targetId;
    });
  });

  // Handle hash in URL on page load
  if (window.location.hash) {
    const hashId = window.location.hash.replace('#', '');
    const exists = Array.from(sections).some(sec => sec.id === hashId);
    if (exists) {
      navigateTo(hashId);
    }
  }

  // Copy code buttons
  const copyButtons = document.querySelectorAll('.copy-btn');
  copyButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      const codeId = btn.dataset.copy;
      const codeElement = document.getElementById(codeId);
      if (codeElement) {
        navigator.clipboard.writeText(codeElement.innerText).then(() => {
          const originalText = btn.innerText;
          btn.innerText = '¡Copiado!';
          btn.style.backgroundColor = '#34d399';
          btn.style.color = '#0f172a';

          setTimeout(() => {
            btn.innerText = originalText;
            btn.style.backgroundColor = '';
            btn.style.color = '';
          }, 1800);
        });
      }
    });
  });

  // Instant Live Search
  const searchInput = document.getElementById('searchInput');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const query = e.target.value.toLowerCase().trim();
      if (!query) return;

      // Filter troubleshooting and text blocks
      const troubleItems = document.querySelectorAll('.trouble-item');
      troubleItems.forEach(item => {
        const text = item.innerText.toLowerCase();
        if (text.includes(query)) {
          item.style.display = 'flex';
          item.style.borderLeftColor = '#38bdf8';
        } else {
          item.style.display = 'none';
        }
      });
    });

    // Keyboard shortcut Ctrl+K
    window.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        searchInput.focus();
      }
    });
  }
});
