## Description

- _describe the problem_

## Checklist

Please ensure the following are completed before requesting review:

### General Tests

- [ ] I have run **unit tests** locally
- [ ] I have run **integration tests** locally
- [ ] I have run **widget tests** locally
- [ ] I have **added new tests** to cover any new logic or features introduced in this PR (if applicable).
- [ ] I have reviewed my code.

---

### Functional Testing
- [ ] All core features touched by this PR work as expected.
- [ ] Background tasks (e.g., timers, notifications) are not broken by these changes.

---

### UI/UX & Responsiveness (if applicable)
- [ ] Layouts render correctly on different screen sizes and orientations.
- [ ] Scrollable areas are fully accessible, and no content is clipped.
- [ ] All interactive elements are properly aligned.
- [ ] Animations run smoothly and without visual glitches.

---
### Performance (if applicable)
- [ ] No noticeable delay added to screen loading or transitions.
- [ ] App launch time remains within acceptable limits (Ideal: ≤ 1.5s, Acceptable: ≤ 2s).

> _Note for reviewers_: Please verify that tests (Widget, Units, and Integration) are passing before approving.

