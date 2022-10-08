from pdb import set_trace as st
import os
import numpy as np
import cv2
import glob
import argparse

parser = argparse.ArgumentParser('create image pairs')
parser.add_argument('--fold_A', dest='fold_A', help='input directory for image A', type=str, default=r'F:\simulation')
parser.add_argument('--fold_B', dest='fold_B', help='input directory for image B', type=str, default=r'F:\GT')
parser.add_argument('--fold_AB', dest='fold_AB', help='output directory', type=str, default=r'F:\train')
parser.add_argument('--num_imgs', dest='num_imgs', help='number of images', type=int, default=1000000)
parser.add_argument('--use_AB', dest='use_AB', help='if true: (0001_A, 0001_B) to (0001_AB)',action='store_true')
args = parser.parse_args()

for arg in vars(args):
    print('[%s] = ' % arg,  getattr(args, arg))

if not os.path.exists(args.fold_AB):
    os.makedirs(args.fold_AB)

splits = glob.glob(args.fold_A + '\\' + '*.png')
splits_B = glob.glob(args.fold_B + '\\' + '*.png')
print(splits)
print(splits_B)
cnt = 0
for i, sp in enumerate(splits):
    path_A = sp
    im_A = cv2.imread(path_A, -1)
    print(i)

    path_B = splits_B[i]
    im_B = cv2.imread(path_B, -1) 

    cnt += 1

    im_AB = np.concatenate([im_A, im_B], 1)

    cv2.imwrite(args.fold_AB + '\\'+'%04d.png' % (cnt), im_AB)

print('over')
