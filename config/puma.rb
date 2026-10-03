# frozen_string_literal: true

# Puma configuration, loaded automatically by `bundle exec puma`.
#
# SECURITY: this API has NO authentication. Any request that reaches it can
# create, change and delete users, products and payments. The only thing
# keeping that out of reach is the bind address below: 127.0.0.1 is the
# loopback interface, which exists only inside this machine, so no other
# computer on the same network (nor anything on the internet, behind a router
# or a tunnel) can open a connection.
#
# Do not replace it with 0.0.0.0 on a shared or public machine.

# The port the server answers on. PORT is what `bin/test` sets, to move the
# end-to-end server away from the port used during development so the two never
# mix. Everything else uses the default.
bind "tcp://127.0.0.1:#{ENV.fetch("PORT", "9292")}"

# One process is enough for a local server, and keeping it at one is also what
# makes Ctrl+C in `bin/start` stop it right away. Threads answer the requests.
threads 1, 5

# The size of the request body is NOT limited here: Puma has no setting for it.
# The limit belongs to the application, which is the only one that can answer
# with a proper 413 - see MAX_BODY_BYTES in helpers/json.rb.
