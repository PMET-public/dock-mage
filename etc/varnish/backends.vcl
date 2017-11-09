backend m2_app_server_internal {
  .host = "m2-app-server.internal";
  .port = "80";
}

sub set_backend {
    set req.backend_hint = m2_app_server_internal;
}
