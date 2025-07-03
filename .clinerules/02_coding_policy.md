# Coding Policy and Test Practices

This document outlines the coding standards and testing practices for this repository. The goal is to ensure high code quality, maintainability, and reliability, with a strong emphasis on Test-Driven Development (TDD), unit testing, and end-to-end (E2E) testing.

---

## 1. General Coding Standards

- **Follow language-specific best practices** (e.g., idiomatic Go for Go code, POSIX-compliant shell scripting).
- **Write clear, maintainable, and well-documented code.**
- **Adhere to existing project structure and conventions.**
- **Use descriptive names** for variables, functions, and files.
- **Keep functions and modules small and focused.**
- **Document all public functions, types, and modules.**
- **Avoid code duplication**; prefer reusable abstractions.

---

## 2. Test-Driven Development (TDD) Approach

- **Write tests before implementing new features or bug fixes.**
- **Start with a failing test** that describes the desired behavior or bug.
- **Implement the minimal code required to pass the test.**
- **Refactor code for clarity and maintainability, ensuring all tests remain green.**
- **Repeat for each new feature, improvement, or bug fix.**

---

## 3. Unit Testing

- **All new code must be covered by unit tests.**
- **Unit tests should be fast, isolated, and deterministic.**
- **Use Go's built-in testing framework (`testing` package) for Go code.**
- **For shell scripts, use [bats](https://github.com/bats-core/bats-core) or similar frameworks.**
- **Test edge cases, error handling, and expected behavior.**
- **Place unit tests alongside the code they test (e.g., `foo_test.go` for `foo.go`).**
- **Aim for high code coverage, but prioritize meaningful tests over coverage metrics.**

---

## 4. End-to-End (E2E) Testing

- **E2E tests validate the system as a whole, simulating real-world usage.**
- **Use integration and E2E test suites for the Docker Engine (see `integration/`, `integration-cli/`).**
- **E2E tests should cover critical workflows, cross-component interactions, and user scenarios.**
- **Automate E2E tests in CI/CD pipelines.**
- **Document how to run E2E tests locally and in CI.**

---

## 5. Continuous Integration and Quality Gates

- **All code must pass linting, formatting, and static analysis checks.**
- **All tests (unit and E2E) must pass before merging.**
- **CI pipelines should run on all supported architectures, including new ones (e.g., RISC-V 64).**
- **Code reviews are required for all changes.**

---

## 6. Example TDD Workflow

1. **Write a failing unit test** for a new feature or bug.
2. **Implement the minimal code** to make the test pass.
3. **Refactor** for clarity and maintainability.
4. **Repeat** for additional features or scenarios.
5. **Write or update E2E tests** as needed.
6. **Ensure all tests pass** locally and in CI.

---

## 7. Git Workflow Requirements

**IMPORTANT**: For every user request, you MUST:

1. **Categorize the request** by asking the user to classify it as one of:
   - "new feature" - Adding completely new functionality
   - "feature improvement" - Enhancing existing functionality 
   - "bug fix" - Fixing broken or incorrect behavior
   - "foundation" - Configuration changes, repository setup, or technical debt work

2. **Create a feature branch** based on the classification:
   - Branch naming: `feature/description-of-change`, `improvement/description-of-change`, `bugfix/description-of-change`, or `foundation/description-of-change`
   - Always work on the branch, never directly on master
   - Output the branch name so the user knows which branch to test

3. **Commit all changes** on the feature branch with descriptive commit messages

4. **Wait for user approval** before merging to master
   - User will test the changes on the feature branch
   - Once approved, merge the branch and delete it
   - If rejected, make additional changes on the same branch

5. **Branch and commit output format**: 
   - Always clearly state "Working on branch: `branch-name`" when making changes
   - After committing, output the commit hash and message
   - Format: "Committed on `branch-name`: `commit-hash` - commit message"
   
---

## 8. References

- [Go Testing Documentation](https://golang.org/pkg/testing/)
- [Docker Engine Contribution Guide](https://github.com/moby/moby/blob/master/CONTRIBUTING.md)
- [Test-Driven Development by Example (Kent Beck)](https://www.goodreads.com/book/show/387190.Test_Driven_Development)
- [bats-core for shell script testing](https://github.com/bats-core/bats-core)

---

By following these coding and testing practices, we ensure a robust, maintainable, and future-proof codebase for all supported architectures.
