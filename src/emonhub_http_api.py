import logging
import threading
import json
from wsgiref.simple_server import make_server

class EmonHubHTTPApi(threading.Thread):
    def __init__(self, settings):
        # Initialise logger
        self._log = logging.getLogger("EmonHub")

        # Initialise thread
        super().__init__()
        
        self._settings = settings
        
        self._log.debug("EmonHubHTTPApi Init")

    def hello_world_app(self, environ, start_response):
        ip = environ['REMOTE_ADDR']
        method = environ['REQUEST_METHOD']
        path = environ['PATH_INFO']
        query = environ['QUERY_STRING']

        self._log.debug("HTTP Request received %s %s %s?%s" % (ip,method,path,query))
        
        # Default
        reply_format = 'text/plain'
        reply_string = 'Hello World'
        
        # Routes
        if path=="/config":
            # Fetch config object as json
            if method=="GET":
                reply_format = 'application/json'
                reply_string = json.dumps(self._settings)
            # Set and save config object
            elif method=="POST":
                # the environment variable CONTENT_LENGTH may be empty or missing
                try:
                    request_body_size = int(environ.get('CONTENT_LENGTH', 0))
                except (ValueError):
                    request_body_size = 0
                    
                request_body = environ['wsgi.input'].read(request_body_size)
                settings = json.loads(request_body)
                
                # self._log.debug(settings)
                self._settings.merge(settings)
                self._settings.write()
                self._log.info("emonhub.conf updated via http api")
                 
                reply_format = 'text/plain'
                reply_string = 'ok'
 
        # Set headers
        start_response('200 OK', [('Content-type', reply_format+' charset=utf-8')])       
        return [reply_string.encode('ascii')]
        
    def run(self):
        with make_server('', 8000, self.hello_world_app) as self.httpd:
            self._log.debug("Starting HTTP API Server on port 8000")
            self.httpd.serve_forever()
                
    def stop(self):
        self._log.debug("Stopping HTTP API Server")
        self.httpd.shutdown();