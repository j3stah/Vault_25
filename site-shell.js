(function () {
  const pathname = window.location.pathname;
  const pageName = pathname.split('/').pop() || 'index.html';
  const isWritingPage = pathname.includes('/writings/');
  const isPoemPage = pathname.includes('/poems/');

  const headerPath = isPoemPage
    ? '../poem_header.html'
    : isWritingPage
      ? '../writing_header.html'
      : 'main_pages_header.html';

  const activeNavKey = isPoemPage
    ? 'poems'
    : isWritingPage
      ? 'writings'
      : {
          'index.html': 'home',
          'media_list.html': 'media',
          'all-writings.html': 'writings',
          'journal.html': 'journal',
          'bling.html': 'bling',
          'break_the_vault.html': 'breaksite',
          'all-poems.html': 'poems'
        }[pageName] || null;

  function applyActiveNav() {
    const header = document.getElementById('header');
    if (!header) return;

    const links = header.querySelectorAll('a[data-nav]');
    links.forEach(link => {
      const isActive = link.getAttribute('data-nav') === activeNavKey;
      link.classList.toggle('active-link', isActive);
    });
  }

  function loadHeader() {
    const header = document.getElementById('header');
    if (!header) return;

    fetch(headerPath)
      .then(response => {
        if (!response.ok) {
          throw new Error(`Unable to load ${headerPath}`);
        }
        return response.text();
      })
      .then(html => {
        header.innerHTML = html;
        applyActiveNav();
      })
      .catch(error => {
        header.innerHTML = '<p class="centered-note">Header could not be loaded.</p>';
        console.error(error);
      });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', loadHeader);
  } else {
    loadHeader();
  }
})();
