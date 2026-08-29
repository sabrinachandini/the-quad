export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { username, password } = req.body || {};
  if (!username || !password) {
    return res.status(400).json({ ok: false, error: 'Missing credentials' });
  }

  const encode = (s) => encodeURIComponent(String(s));
  const body = `username=${encode(username)}&password=${encode(password)}`;

  let authRes, text;
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);
    authRes = await fetch('https://ma-lexington.myfollett.com/app/rest/auth', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'deploymentId': 'ma-lexington',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
      },
      body,
      signal: controller.signal,
    });
    clearTimeout(timeout);
    text = await authRes.text();
  } catch (e) {
    const msg = e.name === 'AbortError'
      ? 'Aspen timed out. Try again.'
      : 'Could not reach Aspen: ' + e.message;
    return res.status(502).json({ ok: false, error: msg });
  }

  // Try to parse JSON response
  let data = {};
  try { data = JSON.parse(text); } catch {}

  const status = authRes.status;

  if (status === 401) {
    return res.status(200).json({ ok: false, error: 'Invalid Aspen ID or password.' });
  }
  if (status >= 500) {
    return res.status(200).json({ ok: false, error: 'Aspen is unavailable right now. Try again later.' });
  }
  if (data.message && /invalid|password|username|credential/i.test(data.message)) {
    return res.status(200).json({ ok: false, error: 'Invalid Aspen ID or password.' });
  }
  if (status !== 200) {
    return res.status(200).json({ ok: false, error: `Aspen returned an error (${status}). Check your credentials.` });
  }

  return res.status(200).json({ ok: true, aspenUrl: data.aspenUrl });
}
