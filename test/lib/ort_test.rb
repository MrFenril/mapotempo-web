require 'ort'

class OrtTest < ActionController::TestCase
  setup do
  end

  test "shoud zip" do
    m = [
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
      [[ 1,  1], [ 0,  0], [ 1,  1], [10, 10], [ 1,  1]],
      [[ 1,  1], [ 1,  1], [ 0,  0], [10, 10], [ 1,  1]],
      [[10, 10], [10, 10], [10, 10], [ 0,  0], [10, 10]],
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
    ]
    t = [
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
    ]

    a, b, c = Ort.send(:zip, m, t, 5)

    assert_equal [
      [[ 0,  0], [10, 10], [ 1,  1], [ 0,  0]],
      [[10, 10], [ 0,  0], [10, 10], [10, 10]],
      [[ 1,  1], [10, 10], [ 0,  0], [ 1,  1]],
      [[ 0,  0], [10, 10], [ 1,  1], [ 0,  0]],
    ], a
    assert_equal [0, 3, 2, 1, 4], Ort.send(:unzip, [0, 1, 2, 3], c, m)
  end

  test "shoud not zip" do
    m = [
      [[ 0,  0], [10, 10], [20, 20], [30, 30], [ 0,  0]],
      [[10, 10], [ 0,  0], [30, 30], [40, 40], [10, 10]],
      [[20, 20], [30, 30], [ 0,  0], [50, 50], [20, 20]],
      [[30, 30], [40, 40], [50, 50], [ 0,  0], [30, 30]],
      [[ 0,  0], [10, 10], [20, 20], [30, 30], [ 0,  0]],
    ]
    t = [
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
      [nil, nil, 0],
    ]

    a, b, c = Ort.send(:zip, m, t, 5)

    assert_equal m, a
    assert_equal [0, 1, 2, 3, 4], Ort.send(:unzip, [0, 1, 2, 3, 4], c, m)
  end

  test "shoud not zip, tw" do
    m = [
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
      [[ 1,  1], [ 0,  0], [ 1,  1], [10, 10], [ 1,  1]],
      [[ 1,  1], [ 1,  1], [ 0,  0], [10, 10], [ 1,  1]],
      [[10, 10], [10, 10], [10, 10], [ 0,  0], [10, 10]],
      [[ 0,  0], [ 1,  1], [ 1,  1], [10, 10], [ 0,  0]],
    ]
    t = [
      [nil, nil, 0],
      [nil, nil, 1],
      [nil, nil, 0],
      [nil, nil, 0],
    ]
    a, b, c = Ort.send(:zip, m, t, 5)

    assert_equal m, a
    assert_equal [0, 1, 2, 3, 4], Ort.send(:unzip, [0, 1, 2, 3, 4], c, m)
  end

  test "shoud not zip true case" do
    m = [
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]],
      [[603, 603], [0, 0], [1692, 1692], [4977, 4977], [2715, 2715], [603, 603]],
      [[1861, 1861], [1636, 1636], [0, 0], [6143, 6143], [1532, 1532], [1861, 1861]],
      [[5184, 5184], [4951, 4951], [6221, 6221], [0, 0], [7244, 7244], [5184, 5184]],
      [[2982, 2982], [2758, 2758], [1652, 1652], [7264, 7264], [0, 0], [2982, 2982]],
      [[0, 0], [655, 655], [1948, 1948], [5231, 5231], [2971, 2971], [0, 0]]]
    t = [[nil, nil, 0], [nil, nil, 1], [nil, nil, 2], [nil, nil, 3], [nil, nil, 4]]

    a, b, c = Ort.send(:zip, m, t, 5)

    assert_equal m, a
    assert_equal t, b
    assert_equal [0, 1, 2, 3, 4, 5], Ort.send(:unzip, [0, 1, 2, 3, 4, 5], c, m)
  end

  test "shoud zip true case" do
    m = [
      [[0, 0], [693, 693], [655, 655], [1948, 1948], [693, 693], [0, 0]],
      [[609, 609], [0, 0], [416, 416], [2070, 2070], [0, 0], [609, 609]],
      [[603, 603], [489, 489], [0, 0], [1692, 1692], [489, 489], [603, 603]],
      [[1861, 1861], [1933, 1933], [1636, 1636], [0, 0], [1933, 1933], [1861, 1861]],
      [[609, 609], [0, 0], [416, 416], [2070, 2070], [0, 0], [609, 609]],
      [[0, 0], [693, 693], [655, 655], [1948, 1948], [693, 693], [0, 0]]]
    t = [[nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0]]

    a, b, c = Ort.send(:zip, m, t, 5)

    assert_equal [
      [[0, 0], [655, 655], [1948, 1948], [693, 693], [0, 0]],
      [[603, 603], [0, 0], [1692, 1692], [489, 489], [603, 603]],
      [[1861, 1861], [1636, 1636], [0, 0], [1933, 1933], [1861, 1861]],
      [[609, 609], [416, 416], [2070, 2070], [0, 0], [609, 609]],
      [[0, 0], [655, 655], [1948, 1948], [693, 693], [0, 0]]], a
    assert_equal [[nil, nil, 0], [nil, nil, 0], [nil, nil, 0], [nil, nil, 0]], b
    assert_equal [0, 2, 3, 4, 1, 5], Ort.send(:unzip, [0, 1, 2, 3, 4], c, m)
  end
end
