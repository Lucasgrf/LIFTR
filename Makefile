.PHONY: setup app-analyze app-test app-codegen db-reset backend-test backend-lint evals evals-dry

setup:
	cd app && flutter pub get

app-analyze:
	cd app && flutter analyze

app-test:
	cd app && flutter test

app-codegen:
	cd app && dart run build_runner build --delete-conflicting-outputs

db-reset:
	supabase db reset

backend-test:
	deno test --allow-read --allow-env supabase/functions evals

backend-lint:
	deno lint
	deno task check

evals:
	deno run --allow-read --allow-env --allow-net evals/runner.ts

evals-dry:
	deno run --allow-read --allow-env evals/runner.ts --dry-run
