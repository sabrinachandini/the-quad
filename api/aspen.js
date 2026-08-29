export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { username, password } = req.body || {};
  if (!username || !password) return res.status(400).json({ ok: false, error: 'Missing credentials' });

  const encode = (s) => encodeURIComponent(s);
  const body = `username=${encode(username)}&password=${encode(password)}`;

  try {
    const authRes = await fetch('https://ma-lexington.myfollett.com/app/rest/auth', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
        'deploymentId': 'ma-lexington',
        'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15',
      },
      body,
      redirect: 'follow',
    });

    const text = await authRes.text();
    let data = {};
    try { data = JSON.parse(text); } catch {}

    if (authRes.status === 401 || (data.message && /invalid|password|username/i.test(data.message))) {
      return res.status(401).json({ ok: false, error: 'Invalid Aspen ID or password.' });
    }
    if (authRes.status >= 500) {
      return res.status(502).json({ ok: false, error: 'Aspen is unavailable. Try again later.' });
    }
    if (authRes.status !== 200) {
      return res.status(authRes.status).json({ ok: false, error: `Aspen returned ${authRes.status}` });
    }

    return res.status(200).json({ ok: true, aspenUrl: data.aspenUrl });
  } catch (e) {
    return res.status(500).json({ ok: false, error: 'Could not reach Aspen: ' + e.message });
  }
}
