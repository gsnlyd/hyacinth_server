import os
import argparse

import numpy as np
import pydicom
from pydicom import uid
from pydicom.dataset import FileDataset, FileMetaDataset

def generate(series_path: str, series_uid: str, instance_num: int):
    file_path = os.path.join(series_path, f'slice{instance_num}.dcm')

    # File Metadata
    file_meta = FileMetaDataset()
    file_meta.MediaStorageSOPClassUID = uid.MRImageStorage
    file_meta.MediaStorageSOPInstanceUID = uid.UID('1.2.3')
    file_meta.ImplementationClassUID = uid.UID('1.2.3.4')

    # Create image
    ds = FileDataset(
        file_path,
        {},
        file_meta=file_meta,
        preamble=b'\0' * 128,
    )

    # Set UIDs and instance number
    ds.StudyInstanceUID = '100.2.3'
    ds.SeriesInstanceUID = series_uid
    ds.InstanceNumber = instance_num

    # Set additional tags for first dcm
    if instance_num == 0:
        ds.PatientName = 'John Doe'
        ds.PatientID = '123'

    # Set orientation/position tags
    ds.PatientPosition = 'HFS'
    ds.ImagePositionPatient = [0, 0, instance_num * 100]
    ds.ImageOrientationPatient = [1, 0, 0, 0, 1, 0]

    ds.SliceThickness = 100
    ds.SliceLocation = instance_num * 100
    ds.PixelSpacing = [100, 100]

    # Set transport syntax fields
    ds.is_little_endian = True
    ds.is_implicit_VR = True

    # Set pixel data
    pixel_data = np.random.rand(100, 100)
    ds.PixelData = pixel_data
    ds.Rows = 100
    ds.Columns = 100

    # Save dcm
    ds.save_as(file_path, write_like_original=False)


def main(num_images: int, dataset_path: str):
    for image_i in range(num_images):
        series_uid = f'200.1.{image_i}'
        image_path = os.path.join(dataset_path, f'image{image_i}')
        if not os.path.exists(image_path):
            os.mkdir(image_path)

        for slice_i in range(100):
            generate(image_path, series_uid, slice_i)

    print(f'Generated {num_images} images at path {dataset_path}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('num_images', type=int)
    parser.add_argument('dataset_path', type=str)

    args = parser.parse_args()
    main(args.num_images, args.dataset_path)
