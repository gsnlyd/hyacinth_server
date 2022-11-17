import os
import argparse
import numpy as np
import nibabel
from PIL import Image


def main(file_path: str, slice_plane: str):
    if slice_plane not in ['sagittal', 'coronal', 'axial']:
        raise ArgumentError()

    img = nibabel.load(file_path)
    img = nibabel.as_closest_canonical(img)

    fdata = img.get_fdata()

    if slice_plane == 'sagittal':
        i_max = fdata.shape[0]
    elif slice_plane == 'coronal':
        i_max = fdata.shape[1]
    elif slice_plane == 'axial':
        i_max = fdata.shape[2]

    output_dir = os.path.join(os.path.dirname(file_path), 'output')
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
        print(f'Created output dir: {output_dir}')

    for i in range(0, i_max):
        if slice_plane == 'sagittal':
            img_slice_data = fdata[i, :, :]
        elif slice_plane == 'coronal':
            img_slice_data = fdata[:, i, :]
        elif slice_plane == 'axial':
            img_slice_data = fdata[:, :, i]

        img_slice_data = np.rot90(img_slice_data, 1)

        img_slice = Image.fromarray(img_slice_data)
        img_slice = img_slice.convert('RGB')

        save_path = os.path.join(output_dir, f'slice_{slice_plane}_{i:03}.png')
        img_slice.save(save_path)

    print(f'Wrote {i_max} images')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Basic nifti slicer written in python.')
    parser.add_argument('file_path', type=str, help='The path of the nifti file to slice.')
    parser.add_argument('slice_plane', choices=['sagittal', 'coronal', 'axial'], help='The plane to slice in: sagittal, coronal, or axial.')
    args = parser.parse_args()
    main(args.file_path, args.slice_plane)
