import os
import argparse
import nibabel
from PIL import Image


def main(file_path: str):
    img = nibabel.load(file_path)
    img = nibabel.as_closest_canonical(img)

    fdata = img.get_fdata()

    i_max = fdata.shape[0]
    output_dir = os.path.join(os.path.dirname(file_path), 'output')
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
        print(f'Created output dir: {output_dir}')

    for i in range(0, i_max):
        img_slice_data = fdata[i, :, :]

        img_slice = Image.fromarray(img_slice_data)
        img_slice = img_slice.convert('RGB')

        save_path = os.path.join(output_dir, f'slice{i}.png')
        img_slice.save(save_path)

    print(f'Wrote {i_max} images')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Basic nifti slicer written in python.')
    parser.add_argument('file_path', type=str, help='The path of the nifti file to slice.')
    args = parser.parse_args()
    main(args.file_path)
