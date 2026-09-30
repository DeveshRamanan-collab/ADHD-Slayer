// CloudFront Functions (JavaScript runtime 2.0), viewer request, cdn distribution default behaviour.
//
// The CDN fronts the API for /v1/config* and /v1/copy/* only (backend/CONTRACT.md). Every other
// path gets a 404 at the edge, so the CDN can't be used as a second door into the API.
function handler(event) {
  return {
    statusCode: 404,
    statusDescription: 'Not Found',
    headers: {
      'content-type': { value: 'application/json' },
      'cache-control': { value: 'no-store' },
    },
    body: {
      encoding: 'text',
      data: '{"error":{"code":"NOT_FOUND","message":"The CDN serves /v1/config and /v1/copy/ only.","details":{}}}',
    },
  };
}
