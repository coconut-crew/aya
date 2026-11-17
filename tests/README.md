# LLM tests

All of the tests in `llm/` are LLM-generated, as the name suggests. While a lot of these tests are good enough, they should not be treated as the sole source of truth for testing.

# Needs work

- Snapshot tests & fuzz tests should be preferred over LLM tests.
- Do not bother with lots of unit tests. Unit tests are not a good way of ensuring software works.
