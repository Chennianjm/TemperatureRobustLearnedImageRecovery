import cv2


def img_to_GRAY(img):
    # 把图片转换为灰度图
    gray_img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # 获取灰度图矩阵的行数和列数
    r, c = gray_img.shape[:2]
    piexs_sum = r * c  # 整个图的像素个数
    # 遍历灰度图的所有像素
    # 灰度值小于60被认为是黑
    dark_points = (gray_img < 60**(1/2.2))
    target_array = gray_img[dark_points]
    dark_sum = target_array.size  # 偏暗的像素
    dark_prop = dark_sum / (piexs_sum)  # 偏暗像素所占比例
    if dark_prop >= 0.60:  # 若偏暗像素所占比例超过0.6,认为为整体环境黑暗的图片
        return 1
    else:
        return 0

def distinguish_dark(image):
    image = image.squeeze(dim=0).permute(1, 2, 0).cpu().numpy()
    image = (image/2 + 0.5)*(255**(1/2.2))
    flag = img_to_GRAY(image)
    return 1 if flag else 0







