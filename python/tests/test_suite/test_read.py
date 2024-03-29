import os
import pytest
import numpy as np
import rainbow_imager_readfile

# globals
DATA_DIR = "%s/data" % (os.path.dirname(os.path.realpath(__file__)))


@pytest.mark.parametrize("test_dict", [
    {
        "filename": "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filename": "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filename": "20130205_0505_rabb_rainbow-08_full.pgm",
        "expected_success": True,
        "expected_frames": 10
    },
])
def test_read_single_file(test_dict):
    # read file
    img, meta, problematic_files = rainbow_imager_readfile.read("%s/%s" % (DATA_DIR, test_dict["filename"]))

    # check success
    if (test_dict["expected_success"] is True):
        assert len(problematic_files) == 0
    else:
        assert len(problematic_files) > 0

    # check number of frames
    assert img.shape == (256, 512, test_dict["expected_frames"])
    assert len(meta) == test_dict["expected_frames"]

    # check dtype
    assert img.dtype == np.uint16


@pytest.mark.parametrize("test_dict", [
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        ],
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filenames": [
            "20130205_0505_rabb_rainbow-08_full.pgm",
        ],
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        ],
        "expected_success": True,
        "expected_frames": 20
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0505_rabb_rainbow-08_full.pgm",
        ],
        "expected_success": True,
        "expected_frames": 30
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "expected_success": True,
        "expected_frames": 50
    },
])
def test_read_multiple_files(test_dict):
    # build file list
    file_list = []
    for f in test_dict["filenames"]:
        file_list.append("%s/%s" % (DATA_DIR, f))

    # read file
    img, meta, problematic_files = rainbow_imager_readfile.read(file_list)

    # check success
    if (test_dict["expected_success"] is True):
        assert len(problematic_files) == 0
    else:
        assert len(problematic_files) > 0

    # check number of frames
    assert img.shape == (256, 512, test_dict["expected_frames"])
    assert len(meta) == test_dict["expected_frames"]

    # check that there's metadata
    for m in meta:
        assert len(m) > 0

    # check dtype
    assert img.dtype == np.uint16


@pytest.mark.parametrize("test_dict", [
    {
        "filename": "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        "workers": 1,
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filename": "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        "workers": 2,
        "expected_success": True,
        "expected_frames": 10
    },
])
def test_read_single_file_workers(test_dict):
    # read file
    img, meta, problematic_files = rainbow_imager_readfile.read(
        "%s/%s" % (DATA_DIR, test_dict["filename"]),
        workers=test_dict["workers"],
    )

    # check success
    if (test_dict["expected_success"] is True):
        assert len(problematic_files) == 0
    else:
        assert len(problematic_files) > 0

    # check number of frames
    assert img.shape == (256, 512, test_dict["expected_frames"])
    assert len(meta) == test_dict["expected_frames"]

    # check that there's metadata
    for m in meta:
        assert len(m) > 0

    # check dtype
    assert img.dtype == np.uint16


@pytest.mark.parametrize("test_dict", [
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 20
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 20
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 50
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 50
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 5,
        "expected_success": True,
        "expected_frames": 50
    },
])
def test_read_multiple_files_workers(test_dict):
    # build file list
    file_list = []
    for f in test_dict["filenames"]:
        file_list.append("%s/%s" % (DATA_DIR, f))

    # read file
    img, meta, problematic_files = rainbow_imager_readfile.read(
        file_list,
        workers=test_dict["workers"],
    )

    # check success
    if (test_dict["expected_success"] is True):
        assert len(problematic_files) == 0
    else:
        assert len(problematic_files) > 0

    # check number of frames
    assert img.shape == (256, 512, test_dict["expected_frames"])
    assert len(meta) == test_dict["expected_frames"]

    # check that there's metadata
    for m in meta:
        assert len(m) > 0

    # check dtype
    assert img.dtype == np.uint16


@pytest.mark.parametrize("test_dict", [
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 1
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 1
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 2
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 2
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0505_rabb_rainbow-08_full.pgm",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 3
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 5
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 5
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 5,
        "expected_success": True,
        "expected_frames": 5
    },
])
def test_read_first_frame(test_dict):
    # build file list
    file_list = []
    for f in test_dict["filenames"]:
        file_list.append("%s/%s" % (DATA_DIR, f))

    # read file
    img, meta, problematic_files = rainbow_imager_readfile.read(
        file_list,
        workers=test_dict["workers"],
        first_frame=True,
    )

    # check success
    if (test_dict["expected_success"] is True):
        assert len(problematic_files) == 0
    else:
        assert len(problematic_files) > 0

    # check number of frames
    assert img.shape == (256, 512, test_dict["expected_frames"])
    assert len(meta) == test_dict["expected_frames"]

    # check that there's metadata
    for m in meta:
        assert len(m) > 0

    # check dtype
    assert img.dtype == np.uint16


@pytest.mark.parametrize("test_dict", [
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 10
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 20
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0505_rabb_rainbow-08_full.pgm",
        ],
        "workers": 3,
        "expected_success": True,
        "expected_frames": 30
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 5,
        "expected_success": True,
        "expected_frames": 50
    },
])
def test_read_no_metadata(test_dict):
    # build file list
    file_list = []
    for f in test_dict["filenames"]:
        file_list.append("%s/%s" % (DATA_DIR, f))

    # read file
    img, meta, problematic_files = rainbow_imager_readfile.read(
        file_list,
        workers=test_dict["workers"],
        no_metadata=True,
    )

    # check success
    if (test_dict["expected_success"] is True):
        assert len(problematic_files) == 0
    else:
        assert len(problematic_files) > 0

    # check number of frames
    assert img.shape == (256, 512, test_dict["expected_frames"])
    assert len(meta) == test_dict["expected_frames"]

    # check that there's no metadata
    for m in meta:
        assert len(m) == 0

    # check dtype
    assert img.dtype == np.uint16


@pytest.mark.parametrize("test_dict", [
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 1,
        "expected_success": True,
        "expected_frames": 1
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 2,
        "expected_success": True,
        "expected_frames": 2
    },
    {
        "filenames": [
            "20130205_0500_rabb_rainbow-08_full.pgm.gz",
            "20130205_0501_rabb_rainbow-08_full.pgm.gz",
            "20130205_0502_rabb_rainbow-08_full.pgm.gz",
            "20130205_0503_rabb_rainbow-08_full.pgm.gz",
            "20130205_0504_rabb_rainbow-08_full.pgm.gz",
        ],
        "workers": 5,
        "expected_success": True,
        "expected_frames": 5
    },
])
def test_read_first_frame_and_no_metadata(test_dict):
    # build file list
    file_list = []
    for f in test_dict["filenames"]:
        file_list.append("%s/%s" % (DATA_DIR, f))

    # read file
    img, meta, problematic_files = rainbow_imager_readfile.read(
        file_list,
        workers=test_dict["workers"],
        first_frame=True,
        no_metadata=True,
    )

    # check success
    if (test_dict["expected_success"] is True):
        assert len(problematic_files) == 0
    else:
        assert len(problematic_files) > 0

    # check number of frames
    assert img.shape == (256, 512, test_dict["expected_frames"])
    assert len(meta) == test_dict["expected_frames"]

    # check that there's no metadata
    for m in meta:
        assert len(m) == 0

    # check dtype
    assert img.dtype == np.uint16
