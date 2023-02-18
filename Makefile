.PHONY: docs format diagrams
format:
	terraform fmt --recursive
	terragrunt hclfmt
docs: format diagrams
	find . -name main.tf -not -path '*/.ter*' | xargs dirname | xargs -I % sh -c 'cd %; terraform-docs markdown . > README.md'
diagrams:
	find diagrams -name \*.py | xargs -I % sh -c 'cd images; python3 ../%'
