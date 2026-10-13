import { useState } from 'react';
import { useAuth0 } from '@auth0/auth0-react';

export default function App() {
  const { loginWithRedirect, logout, isAuthenticated, user, getAccessTokenSilently } = useAuth0();
  const [result, setResult] = useState('');
  const [error, setError] = useState('');

  async function callApi() {
    setError('');
    setResult('');
    try {
      const token = await getAccessTokenSilently();
      const response = await fetch(`${import.meta.env.VITE_API_URL}/api/risk-status`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        setError(`API error: ${response.status} ${response.statusText}`);
        return;
      }
      setResult(JSON.stringify(await response.json(), null, 2));
    } catch (err) {
      setError(err.message);
    }
  }

  if (!isAuthenticated) {
    return (
      <main>
        <h1>Enterprise Risk Lab</h1>
        <button onClick={() => loginWithRedirect()}>Log in</button>
      </main>
    );
  }

  return (
    <main>
      <h1>Enterprise Risk Lab</h1>
      <p>Signed in as {user.name}</p>
      <button onClick={callApi}>Call protected API</button>
      <button onClick={() => logout({ logoutParams: { returnTo: window.location.origin } })}>
        Log out
      </button>
      {error && <pre style={{ color: 'red' }}>{error}</pre>}
      {result && <pre>{result}</pre>}
    </main>
  );
}
