/// Non-web fallback (tests). The admin panel only ships for the web.
void downloadText(String fileName, String content, {String mime = 'text/csv'}) {
  lastDownload = (fileName, content);
}

/// Captured for tests.
(String, String)? lastDownload;
