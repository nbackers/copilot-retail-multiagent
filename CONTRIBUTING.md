# Contributing

Contributions welcome, particularly around **routing accuracy** - the hardest part of a multi-agent
build and the least documented.

## Useful contributions
- **Routing results.** If a question consistently reaches the wrong agent, that's a description
  problem worth documenting. Include the question, where it went, and where it should have gone.
- **Additional cross-cutting skills.** The bar is that it must genuinely span two or more domains.
  A single-domain skill belongs in a child agent's instructions instead.
- **Domain rules.** Retail rules that are commonly got wrong, like available-to-sell.
- **Corrections.** If something here is wrong, say so plainly.

## Pull requests

1. One concern per PR.
2. Skills must keep `SKILL.md` at the folder root, with `name` matching the folder name in
   lowercase kebab case.
3. Write files as **UTF-8 without BOM** - a BOM breaks front matter parsing on upload.
4. Keep the fictitious identity (`Northwind Retail Group`, prefix `nwr_`). Never introduce a real
   retailer, product, supplier or store name.
5. If you add a skill, add its demo hook and say which domains it spans.
6. Business rules belong in skill steps, not agent instructions. If you're adding a sentence to an
   instruction block to fix behaviour, check whether it's really a skill change.

## Anonymity

This repo is deliberately generic. No real organisation, environment, tenant or dataset should
appear anywhere in it. Run the pre-publish scan before pushing.

## Code of conduct

Be constructive and assume good faith.
