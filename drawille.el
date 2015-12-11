;;; drawille.el --- Drawille implementation in elisp

;; Copyright (C) 2015-2016 Josuah Demangeon

;; Author: Josuah Demangeon <josuah.demangeon@gmail.com>
;; Created: 09 Dec 2015
;; Version: 0.1
;; Keywords: graphics
;; URL: https://github.com/sshbio/elisp-drawille
;; Package-Requires: ((cl-lib "0.5"))

;; This file is not part of GNU Emacs.
;; However, it is distributed under the same license.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Change-log:

;;; Commentary:

;; This is an experimental drawille implementation im emacs lisp.

;; This will result into transforming a matrices:

;; [[a0 a1 a2 a3 a4 a5]   [[[a0 a1   [a2 a3   [a4 a5   \
;;  [b0 b1 b2 b3 b4 b5]      b0 b1  / b2 b3  / b4 b5   |<- One braille
;;  [c0 c1 c2 c3 c4 c5]      c0 c1 /  c2 c3 /  c4 c5   |   character
;;  [d0 d1 d2 d3 d4 d5]      d0 d1]   d2 d3]   d4 d5]] /
;;  [e0 e1 e2 e3 e4 e5]    [[e0 e1   [e2 e3   [e4 e5
;;  [f0 f1 f2 f3 f4 f5]      f0 f1  / f2 f3  / f4 f5
;;  [g0 g1 g2 g3 g4 g5]      g0 g1 /  g2 g3 /  g4 g5
;;  [h0 h1 h2 h3 h4 h5]]     h0 h1]   h2 h3]   h4 h5]]]

;; Which is more correctly written as:

;; [[[a0 a1 b0 b1 c0 c1 d0 d1] <- One braille character
;;   [a2 a3 b2 b3 c2 c3 d2 d3]
;;   [a4 a5 b4 b5 c4 c5 d4 d5]] <- One row of braille characters
;;  [[e0 e1 f0 f1 g0 g1 h0 h1]
;;   [e2 e3 f2 f3 g2 g3 h2 h3]
;;   [e4 e5 f4 f5 g4 g5 h4 h5]]] <- Two row of braille characters

;; With each row a vector of 0 or 1, that is multiplied pairwise, and
;; aditionned to #x2800 produce a braille character keycode.

;;; Code:

(require 'cl-lib)

(defconst drawille-braille-unicode-offset #x2800
  "Offeset to reach the first braille char in unicode encoding.")

(defconst drawille-braille-table
  [#x01 #x08 #x02 #x10 #x04 #x20 #x40 #x80]
  "Table to convert coordinates to braille character.")

(defun drawille-vector-to-char (vector)
  "Translate a VECTOR to a corresponding braille character."
  (let (char-codes)
    (cl-dotimes (i 8)
      (push (* (aref vector i)
               (aref drawille-braille-table i))
            char-codes))
    (char-to-string
     (apply '+ drawille-braille-unicode-offset char-codes))))

(defun drawille-vector-at-pos (matrix x y)
  "Return a braille char corresponding to MATRIX at X, Y."
  (let (sub-matrix)
    (dotimes (i 4)
      (dotimes (j 2)
        (set 'sub-matrix
             (vconcat sub-matrix
                      (vector (aref (aref matrix (+ x i)) (+ y j)))))))
    sub-matrix))

(defun drawille-fill-matrix (matrix)
  "Return a MATRIX filled until there are a multiple of 4 of rows."
  (let* ((width (length (aref matrix 0)))
         (height (length matrix)))
    (if (= (% height 4) 0)
        matrix
      (vconcat
       matrix
       (make-vector (- 4 (% height 4))
                    (make-vector width 0))))))

(defun drawille-convert-matrix (unfilled-matrix)
  "Fill an UNFILLED-MATRIX and subdivides it into a matrix of vector.
It will then call `drawille-vector-to-char' to fill rows, then
columns."
  (let* ((matrix (drawille-fill-matrix unfilled-matrix))
         (width (length (aref matrix 0)))
         (height (length matrix)))
    (apply 'vector
           (cl-loop for i from 0 to (1- (floor height 4))
                    collect
            (apply 'vector
                   (cl-loop for j from 0 to (1- (floor width 2))
                            collect
                            (drawille-vector-at-pos
                             matrix (* 4 i) (* 2 j))))))))

(defun drawille-matrix (matrix)
  "Convert MATRIX to an intermediate and then convert it to a string.
The conversion to the inermediate is done via drawille-convert-matrix"
  (let ((converted-matrix (drawille-convert-matrix matrix))
	(result))
    (cl-loop for i from 0 to (1- (length converted-matrix))
             concat
             (concat
              (cl-loop for j from 0 to
		       (1- (length (aref converted-matrix 0)))
                       concat
		       (drawille-vector-to-char
			(aref (aref converted-matrix i) j)))
	      "\n"))))

(drawille-matrix
 [[0 0 0 1 1 1 1 0 0 0 0 0 1 1 1 1 1 1 1 1 0]
  [0 0 1 1 1 1 1 1 0 0 0 0 1 1 1 1 1 1 1 1 0]
  [0 0 1 1 0 0 1 1 0 0 0 0 1 1 1 0 0 1 1 1 0]
  [0 1 1 0 0 0 0 1 1 0 0 0 1 1 0 0 0 0 1 1 0]
  [0 1 0 0 0 0 0 1 1 0 0 0 1 0 0 0 0 0 0 1 0]
  [0 1 0 0 0 0 1 1 1 0 0 0 1 0 0 0 0 0 0 1 0]
  [0 1 0 0 0 1 1 0 1 0 0 0 1 0 0 1 1 0 0 1 0]
  [0 1 0 0 1 1 0 0 1 0 0 0 1 0 0 1 1 0 0 1 0]
  [0 1 0 1 1 0 0 0 1 0 0 0 1 0 0 1 1 0 0 1 0]
  [0 1 1 1 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 1 0]
  [0 1 1 0 0 0 0 0 1 0 0 0 1 0 0 0 0 0 0 1 0]
  [0 0 1 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 1 0 0]
  [0 0 1 1 0 0 1 1 0 0 0 0 0 1 1 0 0 1 1 0 0]
  [0 0 0 1 1 1 1 0 0 0 0 0 0 0 1 1 1 1 0 0 0]])

(defun drawille-string-list-fill (string-list column)
  "Fill a strings on STRING-LIST up to COLUMN."
  (cl-loop
   for string in string-list
   collect (substring
            (concat string (when (< (length string) column)
                             (make-string (- column (length string))
                                          ?  )))
            0 column)))

(defun drawille-string (string column)
  "Transform a STRING to a minimap with COLUMN width.
As vim-minimap does: https://github.com/severin-lemaignan/vim-minimap"
  (let* ((string-without-spaces
          (replace-regexp-in-string " " " " string))
         (string-without-non-spaces
          (replace-regexp-in-string
           "[^\n  ]" "" string-without-spaces))
         (string-list
          (split-string string-without-non-spaces "\n"))
         (filled-strings-vector
          (drawille-string-list-fill string-list column)))
    (drawille-matrix (vconcat filled-strings-vector))))

;;;###autoload
(defun drawille-buffer ()
  "Generate a drawille for current buffer."
  (interactive)
  (message "%s" (drawille-string (buffer-string) fill-column)))

(provide 'drawille)
;;; drawille.el ends here
