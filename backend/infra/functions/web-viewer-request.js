// CloudFront Functions (JavaScript runtime 2.0), viewer request, website distribution.
//
//  1. Anything under /.well-known/ passes through untouched. Apple fetches
//     /.well-known/apple-app-site-association and follows no redirects.
//  2. www.<domain> redirects permanently to <domain>, keeping the path.
//  3. Clean URLs: /privacy and /privacy/ both serve /privacy/index.html from S3.
//
// Tested in backend/infra/test/functions.test.ts. Keep it free of anything the CloudFront
// runtime lacks (no require, no network, no Node globals).
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.indexOf('/.well-known/') === 0) {
    return request;
  }

  var host = request.headers.host ? request.headers.host.value : '';
  if (host.indexOf('www.') === 0) {
    return {
      statusCode: 301,
      statusDescription: 'Moved Permanently',
      headers: {
        location: { value: 'https://' + host.substring(4) + uri },
        'cache-control': { value: 'public, max-age=3600' },
      },
    };
  }

  if (uri.charAt(uri.length - 1) === '/') {
    request.uri = uri + 'index.html';
  } else if (uri.substring(uri.lastIndexOf('/') + 1).indexOf('.') === -1) {
    request.uri = uri + '/index.html';
  }
  return request;
}
