import vibe.http.server;
import vibe.stream.tls;
import vibe.http.internal.http2.http2 : http2Callback; // ALPN negotiation
import vibe.core.core : runApplication;

void handleTestImage(scope HTTPServerRequest req, scope HTTPServerResponse res)
@safe {
}

void handleRequest(scope HTTPServerRequest req, scope HTTPServerResponse res)
@safe {
	if (req.path == "/") {
		bool isHTTP2 = req.httpVersion == HTTPVersion.HTTP_2;
		res.headers["Content-Type"] = "text/html";
		res.render!("index.dt", req, isHTTP2);

	} else if(req.path == "/request") {
		string reply = "BEGIN dump of received request:\n---\n";
		reply ~= httpMethodString(req.method) ~ " " ~ req.path ~ " " ~ getHTTPVersionString(req.httpVersion);
		foreach(hkey, hvalue; req.headers.byKeyValue) {
			reply ~= "\n" ~ hkey ~ ": " ~ hvalue;
		}
		reply ~= "\n---\nEND of dump";
		res.writeBody(reply);

	} else if(req.path == "/image") {
		handleTestImage(req, res);
	}
}

void main()
{
	import vibe.core.log;
	setLogLevel(LogLevel.trace);
/* ========== HTTPS (h2) support ========== */
	HTTPServerSettings tlsSettings;
	tlsSettings.bindAddresses = ["0.0.0.0"];
	tlsSettings.port = 46785;

	/// setup TLS context by using cert and key in example rootdir
	tlsSettings.tlsContext = createTLSContext(TLSContextKind.server);
	tlsSettings.tlsContext.useCertificateChainFile("server.crt");
	tlsSettings.tlsContext.usePrivateKeyFile("server.key");

	// set alpn callback to support HTTP/2 protocol negotiation
	tlsSettings.tlsContext.alpnCallback(http2Callback);
	listenHTTP!handleRequest(tlsSettings);

	runApplication();
}
