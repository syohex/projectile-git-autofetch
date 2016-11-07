;;; projectile-git-autofetch.el --- automatically fetch git repositories

;; Copyright (C) 2016  Andreas Müller

;; Author: Andreas Müller <code@0x7.ch>
;; Keywords: tools, vc
;; Version: 0.1.0
;; URL: https://github.com/andrmuel/projectile-git-autofetch
;; Package-Requires: ((projectile "0.14.0") (async "1.9") (alert "1.2"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; projectile-git-autofetch can be used to periodically fetch git
;; repositories.  Depending on the value of
;; projectile-git-autofetch-projects, only the repository for the
;; current buffer, all open projects or all projects known to
;; projectile are fetched.

;;; Code:

(require 'projectile)
(require 'async)
(require 'alert)

(defgroup projectile-git-autofetch nil
  "Automatically fetch git repositories."
  :group 'tools)

(define-minor-mode projectile-git-autofetch-mode
  "Fetch git repositories periodically."
  :init-value nil
  :group 'projectile-git-autofetch
  :global t
  :lighter " git-af"
  (if projectile-git-autofetch-mode
      (projectile-git-autofetch-setup)
      (projectile-git-autofetch-stop)))

(defcustom projectile-git-autofetch-projects 'open
  "Which projects to auto-fetch.

Selection of projects that should be automatically fetched."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :safe (lambda (val) (memq val '(current open all)))
  :type '(choice (const current :tag "Project for current buffer only.")
		 (const open    :tag "All open projects.")
		 (const all     :tag "All known projects.")
		 (const nil     :tag "Nothing.")))

(defcustom projectile-git-autofetch-notify t
  "Whether to notify in case of new commits."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :type 'boolean)

(defcustom projectile-git-autofetch-initial-delay 10
  "Initial delay in seconds before fetching."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :type 'integer)

(defcustom projectile-git-autofetch-interval 300
  "Auto-fetch interval in seconds."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :type 'integer)

(defun projectile-git-autofetch-run ()
  "Fetch all repositories and notify user."
  (let ((projects))
    (cond
     ((eq projectile-git-autofetch-projects 'current)
      (setq projects (list (projectile-project-root))))
     ((eq projectile-git-autofetch-projects 'open)
      (setq projects (projectile-open-projects)))
     ((eq projectile-git-autofetch-projects 'all)
      (setq projects projectile-known-projects))
     (t
      (setq projects '())))
    (dolist (project projects)
      (let ((default-directory project))
	(if (and (file-directory-p ".git")
		 (> (length (shell-command-to-string "git config --get remote.origin.url")) 0))
	    (async-start
	     (lambda () (shell-command-to-string "git fetch"))
	     (lambda (git-output)
	       (if (and (> (length git-output) 0)
			projectile-git-autofetch-notify)
		   (alert git-output
			  ':title (format "projectile-git-autofetch: %s" (projectile-project-name)))))))))))

(defun projectile-git-autofetch-setup ()
  "Set up timers to periodically fetch repositories."
  (interactive)
  (if (not (and (boundp 'projectile-git-autofetch-timer) (timerp projectile-git-autofetch-timer)))
      (defvar projectile-git-autofetch-timer
	(run-with-timer
	 projectile-git-autofetch-initial-delay
	 projectile-git-autofetch-interval
	 'projectile-git-autofetch-run))))

(defun projectile-git-autofetch-stop ()
  "Stop auto fetch timers."
  (interactive)
  (cancel-timer projectile-git-autofetch-timer)
  (makunbound 'projectile-git-autofetch-timer))

(provide 'projectile-git-autofetch)
;;; projectile-git-autofetch.el ends here
