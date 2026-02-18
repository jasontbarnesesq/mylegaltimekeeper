const http = require('http');
const https = require('https');
const { URL } = require('url');

const feedUrls = [
  'https://www.cnbc.com/id/20910258/device/rss/rss.html',
  'https://feeds.a.dj.com/rss/WSJcomUSBusiness.xml',
  'https://hbswk.hbs.edu/rss/rss.xml',
  'https://knowledge.wharton.upenn.edu/knowledgefeed.xml',
  'https://feeds.hbr.org/harvardbusiness',
  // Updated Google News RSS format (old ?output=rss format no longer works)
  'https://news.google.com/rss/search?q=family+office+investment&hl=en-US&gl=US&ceid=US:en',
  'https://www.reddit.com/search.rss?q=%22family%20office%22&type=link&limit=20&sort=new',
  'https://www.altassets.net/feed'
  // Removed: rss.mckinseyquarterly.com (domain defunct)
  // Removed: preqin.com RSS (moved behind paywall)
];

// Follows redirects and enforces HTTPS switching when needed
const fetchUrl = (url, maxRedirects = 5) => {
  return new Promise((resolve, reject) => {
    let parsedUrl;
    try {
      parsedUrl = new URL(url);
    } catch (e) {
      return reject(new Error(`Invalid URL: ${url}`));
    }

    const protocol = parsedUrl.protocol === 'https:' ? https : http;

    const options = {
      hostname: parsedUrl.hostname,
      port: parsedUrl.port || undefined,
      path: parsedUrl.pathname + parsedUrl.search,
      headers: {
        'User-Agent': 'Mozilla/5.0 (compatible; RSSReader/1.0)',
        'Accept': 'application/rss+xml, application/atom+xml, text/xml, application/xml, */*'
      }
    };

    protocol.get(options, (res) => {
      // Follow redirects (301, 302, 303, 307, 308)
      if ([301, 302, 303, 307, 308].includes(res.statusCode) && res.headers.location) {
        if (maxRedirects === 0) {
          return reject(new Error('Too many redirects'));
        }
        // Resolve relative redirect URLs against the current URL
        const redirectUrl = new URL(res.headers.location, url).href;
        return resolve(fetchUrl(redirectUrl, maxRedirects - 1));
      }

      if (res.statusCode !== 200) {
        return reject(new Error(`HTTP ${res.statusCode} from ${url}`));
      }

      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
};

const decodeHtmlEntities = (text) => {
  return (text || '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&nbsp;/g, ' ')
    .replace(/&apos;/g, "'");
};

// Unwrap CDATA sections before stripping HTML tags
const unwrapCdata = (text) => {
  return (text || '').replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1');
};

const stripHtml = (html) => {
  return (html || '')
    .replace(/<\/?[^>]+(>|$)/g, '')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&amp;/g, '&')
    .trim();
};

const parseXml = (xml) => {
  const items = [];

  const itemRegex = /(<item[^>]*>([\s\S]*?)<\/item>)|(<entry[^>]*>([\s\S]*?)<\/entry>)/g;
  let itemMatch;

  while ((itemMatch = itemRegex.exec(xml)) !== null) {
    const itemContent = itemMatch[2] || itemMatch[4];

    // Unwrap CDATA before processing so stripHtml doesn't discard the content
    let title = itemContent.match(/<title[^>]*>([\s\S]*?)<\/title>/)?.[1] || '';
    title = stripHtml(decodeHtmlEntities(unwrapCdata(title)));

    let desc = itemContent.match(/<description[^>]*>([\s\S]*?)<\/description>/)?.[1] ||
               itemContent.match(/<summary[^>]*>([\s\S]*?)<\/summary>/)?.[1] ||
               itemContent.match(/<content:encoded[^>]*>([\s\S]*?)<\/content:encoded>/)?.[1] || '';

    desc = unwrapCdata(desc);
    desc = stripHtml(decodeHtmlEntities(desc));
    desc = desc.substring(0, 300);

    // Try Atom-style href attribute first, then RSS-style text content
    const linkMatch = itemContent.match(/<link[^>]*href=['"]([^'"]*)['"]/);
    let link = linkMatch
      ? linkMatch[1]
      : (itemContent.match(/<link[^>]*>([^<]*)<\/link>/)?.[1] || '');
    link = decodeHtmlEntities(link.trim());

    if (title && (desc || link)) {
      items.push({ title, summary: desc, link });
    }
  }

  return items;
};

let allItems = [];

for (const url of feedUrls) {
  try {
    const xml = await fetchUrl(url);
    const items = parseXml(xml).slice(0, 5);
    allItems = allItems.concat(items);
  } catch (err) {
    console.log(`Error fetching ${url}: ${err.message}`);
  }
}

return { items: allItems };
