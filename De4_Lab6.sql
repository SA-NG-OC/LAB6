CREATE DATABASE DEON4
USE DEON4

CREATE TABLE KHACHHANG (
    MaKH CHAR(5) PRIMARY KEY,
    HoTen VARCHAR(30),
    DiaChi VARCHAR(30),
    SoDT VARCHAR(15),
    LoaiKH VARCHAR(10)
);

CREATE TABLE BANG_DIA (
    MaBD CHAR(5) PRIMARY KEY,
    TenBD VARCHAR(25),
    TheLoai VARCHAR(25)
);

CREATE TABLE PHIEUTHUE (
    MaPM CHAR(5) PRIMARY KEY,
    MaKH CHAR(5),
    NgayThue SMALLDATETIME,
    NgayTra SMALLDATETIME,
    Soluongmuon INT,
    FOREIGN KEY (MaKH) REFERENCES KHACHHANG(MaKH)
);

CREATE TABLE CHITIET_PM (
    MaPM CHAR(5),
    MaBD CHAR(5),
    PRIMARY KEY (MaPM, MaBD),
    FOREIGN KEY (MaPM) REFERENCES PHIEUTHUE(MaPM),
    FOREIGN KEY (MaBD) REFERENCES BANG_DIA(MaBD)
);

--2. Hiện thực các ràng buộc toàn vẹn sau:  
--2.1. Thể loại băng đĩa chỉ thuộc các thể loại sau “ca nhạc”, “phim hành động”, “phim tình 
--cảm”, “phim hoạt hình”. (1.5 đ)  
ALTER TABLE BANG_DIA
ADD CONSTRAINT CK_TheLoai
CHECK (TheLoai IN (N'ca nhạc', N'phim hành động', N'phim tình cảm', N'phim hoạt hình'));
--2.2. Chỉ những khách hàng thuộc loại VIP mới được thuê với số lượng băng đĩa trên 5. (1.5 đ)  
GO
CREATE TRIGGER trg_KiemTraLoaiVIP
ON PHIEUTHUE
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN KHACHHANG kh ON i.MaKH = kh.MaKH
        WHERE i.Soluongmuon > 5 AND kh.LoaiKH <> N'VIP'
    )
    BEGIN
        RAISERROR ('Chỉ khách hàng VIP mới được thuê trên 5 băng đĩa.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

--3. Viết các câu lệnh SQL thực hiện các câu truy vấn sau:  
--3.1. Tìm các khách hàng (MaDG,HoTen) đã thuê băng đĩa  thuộc thể loại phim “Tình 
--cảm” có số lượng thuê lớn hơn 3. (1.5 đ)  
SELECT DISTINCT kh.MaKH, kh.HoTen
FROM KHACHHANG kh
JOIN PHIEUTHUE pt ON kh.MaKH = pt.MaKH
JOIN CHITIET_PM ct ON pt.MaPM = ct.MaPM
JOIN BANG_DIA bd ON ct.MaBD = bd.MaBD
WHERE bd.TheLoai = N'phim tình cảm'
AND pt.Soluongmuon > 3;
--3.2. Tìm các khách hàng(MaDG,HoTen) thuộc loại VIP đã thuê nhiều băng đĩa nhất. (1.5 đ)  
SELECT TOP 1 WITH TIES kh.MaKH, kh.HoTen, SUM(pt.Soluongmuon) AS TongSoLuong
FROM KHACHHANG kh
JOIN PHIEUTHUE pt ON kh.MaKH = pt.MaKH
WHERE kh.LoaiKH = N'VIP'
GROUP BY kh.MaKH, kh.HoTen
ORDER BY TongSoLuong DESC;
--3.3. Trong mỗi thể loại băng đĩa, cho biết tên khách hàng nào đã thuê nhiều băng đĩa nhất. (1 đ) 
WITH SoLuongThue AS (
    SELECT bd.TheLoai, kh.MaKH, kh.HoTen, COUNT(*) AS SoLanThue
    FROM KHACHHANG kh
    JOIN PHIEUTHUE pt ON kh.MaKH = pt.MaKH
    JOIN CHITIET_PM ct ON pt.MaPM = ct.MaPM
    JOIN BANG_DIA bd ON ct.MaBD = bd.MaBD
    GROUP BY bd.TheLoai, kh.MaKH, kh.HoTen
),
MaxThue AS (
    SELECT TheLoai, MAX(SoLanThue) AS MaxLanThue
    FROM SoLuongThue
    GROUP BY TheLoai
)
SELECT slt.TheLoai, slt.MaKH, slt.HoTen, slt.SoLanThue
FROM SoLuongThue slt
JOIN MaxThue mt ON slt.TheLoai = mt.TheLoai AND slt.SoLanThue = mt.MaxLanThue;