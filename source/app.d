import vibe.http.server;
import vibe.stream.tls;
import vibe.http.internal.http2.http2 : http2Callback; // ALPN negotiation
import vibe.core.core : runApplication;

void handleRequest(scope HTTPServerRequest req, scope HTTPServerResponse res)
@safe {
	bool isHTTP2 = false;
	if(req.httpVersion == HTTPVersion.HTTP_2) isHTTP2 = true;

	res.headers["Content-Type"] = "text/html";

	res.render!("diet.dt", req, isHTTP2);
}

void main()
{
/* ========== HTTPS (h2) support ========== */
	HTTPServerSettings tlsSettings;
	tlsSettings.port = 8091;
	tlsSettings.bindAddresses = ["127.0.0.1"];

	/// setup TLS context by using cert and key in example rootdir
	tlsSettings.tlsContext = createTLSContext(TLSContextKind.server);
	tlsSettings.tlsContext.useCertificateChainFile("server.crt");
	tlsSettings.tlsContext.usePrivateKeyFile("server.key");

	// set alpn callback to support HTTP/2 protocol negotiation
	tlsSettings.tlsContext.alpnCallback(http2Callback);
	listenHTTP!handleRequest(tlsSettings);

	runApplication();
}
