;;; lda-mode.el --- LDA mode for Emacs               -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Nicolas Richard

;; Author: Nicolas Richard <youngfrog@members.fsf.org>
;; Keywords: convenience

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

;; LDA mode for Emacs. Tentative.

;;; Code:


(defface lda-mode-keyword-face '((t :weight bold)) "Face for LDA keywords")
(define-generic-mode lda-mode
  '("//")
  nil
  `(("<-" . 'font-lock-builtin-face)
    ("->" . 'font-lock-builtin-face)
    (,(regexp-opt '("fin si" "si" "alors" "sinon" "selon que" "vaut" "fin selon que")) . 'lda-mode-keyword-face)
    (,(regexp-opt '("tant que" "faire" "fin tant que" "pour" "de" "à" "fin pour" "jusqu à ce que")) . 'lda-mode-keyword-face)    
    (,(regexp-opt '("vrai" "faux")) . 'lda-mode-keyword-face)
    (,(concat (regexp-opt '("entier" "réel" "caractère" "chaine" "booléen" "tableau")) "s?") . 'font-lock-type-face)
    (,(regexp-opt '("retourner" "afficher" "demander" "écrire" "lire")) . 'lda-mode-keyword-face)
    (,(regexp-opt '("module" "fin module" "structure" "fin structure" "algorithme" "fin algorithme")) . 'lda-mode-keyword-face))
  nil nil nil)



;; Tentative d'utiliser SMIE mais ça marche pas top.

(require 'smie)

;; étant donné nos "fin algorithme" et autres joyeuseries, j'imagine
;; qu'il faut modifier la façon de smie tokenize le buffer. J'ai
;; trouvé le truc suivant dans la doc mais c'était pas vraiment prévu
;; pour ce genre de choses-ci.

(defvar lda-keywords-regexp
  (regexp-opt '("+" "*" "-" "/" "MOD" "DIV" "fin tant que"
                "fin algorithme" "fin si" "tant que" ">"
                ">=" "<" "<=" "<-" "=" "fin pour")))

(defun lda-smie-forward-token ()
  (forward-comment (point-max))
  (cond
   ((looking-at lda-keywords-regexp)
    (goto-char (match-end 0))
    (match-string-no-properties 0))
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-forward "w_")
              (point))))))
(defun lda-smie-backward-token ()
  (forward-comment (- (point)))
  (cond
   ((looking-back lda-keywords-regexp (- (point) 20) t)
    (goto-char (match-beginning 0))
    (match-string-no-properties 0))
   (t (buffer-substring-no-properties
       (point)
       (progn (skip-syntax-backward "w_")
              (point))))))

(defvar lda-grammar (smie-prec2->grammar
                     (smie-bnf->prec2
                      ;; je patauge dans la choucroute ici.
                      '((id)            ; any sexp
                        ;; inst = instructions
                        (inst ("si" exp "alors" inst "sinon" inst "fin si")
                              ("tant" "que" exp "faire" inst "fin tant que")
                              ("faire" insts "fin tant que")
                              ("pour" id "de" id "à" id "faire" insts "fin pour")
                              ("algorithme" insts "fin algorithme")
                              (id "<-" exp)
                              (exp))
                        (insts (inst))
                        (exps (exp))
                        (exp (exp "+" exp)
                             (exp "*" exp)
                             ("(" exps ")")))       
                      '((assoc ","))
                      '((assoc "+") (assoc "*")))))
(define-derived-mode lda2-mode fundamental-mode "LDA2"
  "LDA mode for Emacs"
  (smie-setup lda-grammar #'ignore
              :forward-token #'lda-smie-forward-token
              :backward-token #'lda-smie-backward-token))


(provide 'lda-mode)
;;; lda-mode.el ends here
