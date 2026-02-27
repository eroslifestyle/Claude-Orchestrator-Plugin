# Integration Template

## Pre-Integration Checks
- [ ] All source branches are up to date
- [ ] No merge conflicts detected
- [ ] All tests pass on source branches
- [ ] Code review approved

## Merge Execution
1. Merge source into target branch
2. Resolve any conflicts (document resolution)
3. Run full test suite
4. Verify no regressions

## Post-Merge Validation
- [ ] Build succeeds
- [ ] All tests pass
- [ ] No new warnings introduced
- [ ] Documentation updated if needed
- [ ] Changelog entry added

## Rollback Plan
If integration fails:
1. Revert merge commit
2. Document failure reason
3. Create fix tasks
