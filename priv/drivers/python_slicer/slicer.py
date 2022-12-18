import os
import argparse
import time
import numpy as np
import nibabel
from PIL import Image


def main(file_path: str, slice_plane: str, bit_depth: str, tone_map: str, max_clamp_percentile: int):
    if max_clamp_percentile < 0 or max_clamp_percentile > 100:
        raise ArgumentError('Max clamp percentile must be between 0 and 100')

    start = time.time()
    img = nibabel.load(file_path)
    img = nibabel.as_closest_canonical(img)

    fdata = img.get_fdata()

    if bit_depth == '8bit':
        cast_dtype = np.uint8
        image_mode = 'L'
    elif bit_depth == '16bit':
        cast_dtype = np.uint16
        image_mode = 'I;16'
    else:
        raise ArgumentError('Invalid bit depth')

    if args.tone_map == 'disabled':
        pass
    elif args.tone_map == 'linear':
        dtype_max = np.iinfo(cast_dtype).max
        max_clamp = np.percentile(fdata, max_clamp_percentile)
        print(f'Clamping to {max_clamp_percentile} percentile value: {max_clamp}')
        fdata = (np.clip(fdata, 0, max_clamp) / max_clamp) * dtype_max
    else:
        raise ArgumentError('Inavlid tone map')

    fdata = fdata.astype(cast_dtype)

    if slice_plane == 'sagittal':
        i_max = fdata.shape[0]
    elif slice_plane == 'coronal':
        i_max = fdata.shape[1]
    elif slice_plane == 'axial':
        i_max = fdata.shape[2]
    else:
        raise ArgumentError('Invalid slice plane')

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
        img_slice = Image.fromarray(img_slice_data, mode=image_mode)

        save_path = os.path.join(output_dir, f'slice_{slice_plane}_{i:03}.png')
        img_slice.save(save_path)

    print(f'Wrote {i_max} images in {time.time() - start:.2f} seconds')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Basic nifti slicer written in python.')
    parser.add_argument('file_path', type=str, help='The path of the nifti file to slice.')
    parser.add_argument('slice_plane', choices=['sagittal', 'coronal', 'axial'], help='The plane to slice in: sagittal, coronal, or axial.')
    parser.add_argument('bit_depth', choices=['8bit', '16bit'], help='The bit depth of the output slices.')
    parser.add_argument('tone_map', choices=['disabled', 'linear'], help='Tone mapping strategy.')
    parser.add_argument('max_clamp_percentile', type=int, help='Percentile for max clamp. Only used for linear tone map strategy.')
    args = parser.parse_args()
    main(args.file_path, args.slice_plane, args.bit_depth, args.tone_map, args.max_clamp_percentile)
