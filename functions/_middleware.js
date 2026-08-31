export async function onRequest(context) {
  const request = context.request;
  const url = new URL(request.url);

  if (url.pathname.startsWith("/api/")) {
    return context.next();
  }

  const email = request.headers.get("Cf-Access-Authenticated-User-Email");
  const userId = request.headers.get("Cf-Access-User-Id");

  context.data.user = {
    authenticated: Boolean(email || userId),
    email,
    id: userId
  };

  return context.next();
}
