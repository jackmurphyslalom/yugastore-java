# Local dev environment setup for yugastore-java.
# Run `brew bundle` from the repo root to install everything listed here.
# See https://github.com/jackmurphyslalom/yugastore-java/issues/19

brew "gh"          # GitHub CLI - required by tools/gh-agent-board scripts
brew "jq"          # JSON processor - required by tools/gh-agent-board scripts
brew "bats-core"   # Bash test framework - runs tools/gh-agent-board/tests
brew "openjdk@17"  # Java 17 - builds/runs the Spring Boot microservices
brew "maven"       # Maven build tool for the microservice reactor (mvnw wrapper is also available)
brew "node"        # Node.js/npm - required for react-ui/frontend
brew "python@3.11" # Python 3 - runs resources/parse_metadata_json.py for data loading
brew "wget"        # Fetches the Cassandra loader binary (see resources/README.md)
cask "docker"      # Docker Desktop - required by docker-run.sh
