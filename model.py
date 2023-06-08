import pandas as pd
from sklearn import svm
from sklearn.model_selection import GridSearchCV
import os
import matplotlib.pyplot as plt
from skimage.transform import resize
from skimage.io import imread
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report,accuracy_score,confusion_matrix
import pickle
from google.colab import drive # kết nối với drive
drive.mount('/content/drive')
Categories=['HoaCuc','HoaNhai','HoaGiay'] #Khai báo các loài hoa được phân loại

flat_data_arr=[] #Mảng để lưu dữ liệu ảnh
target_arr=[] #Mản để lưu nhãn tương ứng
datadir='/content/drive/MyDrive/dataset' #Đương dẫn đến thư mục chứa dữ liệu ảnh
for i in Categories: #đọc tất cả các tệp hình ảnh và thực hiện một số xử lý trên ảnh
  print(f'loading... category : {i}')
  path=os.path.join(datadir,i)
  for img in os.listdir(path):
    img_array=imread(os.path.join(path,img))#Hàm imread của thư viện skimage để đọc ảnh

    img_resized=resize(img_array,(150,150,3))
    """ Hàm 'resize' của thư viện skimage để thay đổi kích thước ảnh thành 150x150 
    pixel và 3 kênh màu (RGB).
    """

    flat_data_arr.append(img_resized.flatten())
    #Sử dụng hàm 'flatten' để chuyển đổi ảnh thành một mảng 1 chiều
    #Thêm mảng 1 chiều này vào mảng 'flat_data_arr'.

    target_arr.append(Categories.index(i))
    #Thêm nhãn tương ứng của ảnh vào mảng 'target_arr'.

  print(f'loaded category:{i} successfully')
  #In ra thông báo đã tải xong dữ liệu ảnh cho từng loại hoa.

flat_data=np.array(flat_data_arr)
target=np.array(target_arr)
"""Chuyển đổi mảng 'flat_data_arr' và 'target_arr' thành các mảng numpy và
lưu trữ vào biến 'flat_data' và 'target'."""

df=pd.DataFrame(flat_data)
"""Tạo một DataFrame (df) từ mảng 'flat_data' và 
thêm cột 'Target' chứa nhãn tương ứng vào DataFrame."""


df['Target']=target
#Trả về DataFrame df chứa dữ liệu ảnh và nhãn tương ứng của chúng
df
x=df.iloc[:,:-1]
"""Lấy tất cả các hàng và tất cả các cột trừ cột cuối cùng (nhãn) của DataFrame 'df',
 và lưu trữ nó trong biến 'x'
 """

y=df.iloc[:,-1]
"""Lấy tất cả các hàng và chỉ cột cuối cùng (nhãn) của DataFrame 'df',
 và lưu trữ nó trong biến 'y'.
 """

#Sử dụng hàm 'train_test_split' của thư viện sklearn để chia dữ liệu thành các tập con huấn luyện và kiểm tra.
x_train,x_test,y_train,y_test=train_test_split(x,y,test_size=0.20,random_state=77,stratify=y)
"""
Tham số đầu tiên là dữ liệu đầu vào (x)
Tham số thứ hai là nhãn tương ứng (y). 
Tham số 'test_size=0.20' chỉ định tỷ lệ dữ liệu được chọn làm tập kiểm tra là 20%,
Tham số 'random_state=77' để đảm bảo kết quả chia dữ liệu là cố định và tái sử dụng được. 
Tham số 'stratify=y' để đảm bảo rằng tỷ lệ các lớp trong tập huấn luyện và tập kiểm tra được giữ nguyên.
Lưu trữ các tập huấn luyện và kiểm tra được tạo ra vào
các biến 'x_train', 'x_test', 'y_train', và 'y_test'
"""

#In ra thông báo "Splitted Successfully".
print('Splitted Successfully')
#Định nghĩa một dict 'param_grid' chứa các giá trị siêu tham số khác nhau
param_grid={'C':[0.1,1,10,100],'gamma':[0.0001,0.001,0.1,1],'kernel':['rbf','poly']}
"""
'C' là siêu tham số ứng với tham số điều chỉnh độ lỏng lẻo của ranh giới quyết định,
'gamma' là siêu tham số ứng với siêu tham số kernel của SVM,
'kernel' là siêu tham số ứng với loại kernel sử dụng trong SVM
"""


#Khởi tạo một đối tượng lớp SVM với 'probability=True' để tính toán xác suất dự đoán.
svc=svm.SVC(probability=True)

print("The training of the model is started, please wait for while as it may take few minutes to complete")

#Sử dụng lớp 'GridSearchCV' của thư viện sklearn để tìm kiếm siêu tham số tốt nhất cho mô hình SVM
model=GridSearchCV(svc,param_grid)
"""
Tham số đầu tiên là mô hình SVM (svc)
Tham số thứ hai là dict 'param_grid' chứa các giá trị siêu tham số khác nhau
"""

model.fit(x_train,y_train)
#Phương thức 'fit' sẽ huấn luyện mô hình và tìm kiếm siêu tham số tốt nhất

print('The Model is trained well with the given images')

model.best_params_
#Trả về các siêu tham số tốt nhất được tìm kiếm bằng phương pháp 'best_params_' của lớp 'GridSearchCV'
"""Sử dụng mô hình đã huấn luyện (model) để đưa ra dự đoán 
trên tập kiểm tra (x_test) bằng cách sử dụng phương thức 'predict' của mô hình"""
y_pred=model.predict(x_test)


print("The predicted Data is :")

#In ra kết quả dự đoán 'y_pred'.
y_pred
print("The actual data is:")
np.array(y_test)
#hàm 'np.array' của thư viện numpy để chuyển đổi mảng 'y_test' (nhãn tập kiểm tra) thành một mảng numpy.
print(f"The model is {accuracy_score(y_pred,y_test)*100}% accurate")
pickle.dump(model,open('img_model.p','wb'))
print("Pickle is dumped successfully")