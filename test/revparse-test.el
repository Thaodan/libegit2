(ert-deftest revparse ()
  (let (c1 c2 c3)
    (with-temp-dir path
      (init)
      (commit-change "file" "abcdef")
      (setq c1 (rev-parse))
      (commit-change "file" "ghijkl")
      (setq c2 (rev-parse))
      (commit-change "file" "mnopqr")
      (setq c3 (rev-parse))
      (let* ((repo (libgit-repository-open path)))
        (should (string= c3 (libgit-commit-id (libgit-revparse-single repo "HEAD"))))
        (should (string= c2 (libgit-commit-id (libgit-revparse-single repo "HEAD~"))))
        (should (string= c2 (libgit-commit-id (libgit-revparse-single repo "HEAD^"))))
        (should (string= (libgit-commit-tree-id (libgit-commit-lookup repo c1))
                         (libgit-tree-id (libgit-revparse-single repo "HEAD~2^{tree}"))))
        (let ((res (libgit-revparse-ext repo "HEAD")))
          (should (string= c3 (libgit-commit-id (car res))))
          (should (libgit-reference-p (cdr res)))
          (should (string= "refs/heads/master" (libgit-reference-name (cdr res)))))
        (let ((res (libgit-revparse-ext repo c1)))
          (should (string= c1 (libgit-commit-id (car res))))
          (should-not (cdr res)))
        (let ((res (libgit-revparse repo (format "%s..HEAD" c1))))
          (should-not (car res))
          (should (string= c1 (libgit-commit-id (cadr res))))
          (should (string= c3 (libgit-commit-id (caddr res)))))
        (let ((res (libgit-revparse repo (format "%s...%s" c1 c2))))
          (should (car res))
          (should (string= c1 (libgit-commit-id (cadr res))))
          (should (string= c2 (libgit-commit-id (caddr res)))))))))

(ert-deftest revparse-negative ()
  (let (c1 c2 c3)
    (with-temp-dir path
      (init)
      (commit-change "file1" "abcdef")
      (let ((repo (libgit-repository-open path)))
        (should-error (libgit-revparse-single repo "HEADDDD")
		      :type 'giterr-reference)
	(commit-change "file2" "abcdef")
	(checkout "HEAD^")
	(should (libgit-revparse-single repo "@{-1}"))
	(should-error (libgit-revparse-single repo "@{-2}")
		      :type 'giterr-reference)))))
