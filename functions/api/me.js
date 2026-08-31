export async function onRequest(context) {
  const request = context.request;
  const email = request.headers.get("Cf-Access-Authenticated-User-Email");
  const userId = request.headers.get("Cf-Access-User-Id");
  const country = request.headers.get("Cf-Ipcountry");

  return Response.json({
    authenticated: Boolean(email || userId),
    email,
    id: userId,
    country
  });
}
