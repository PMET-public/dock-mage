backend app {
  .host = "app.internal";
  .port = "80";
}

sub set_backend {
    set req.backend_hint = app;
}
