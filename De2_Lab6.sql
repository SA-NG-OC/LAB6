CREATE DATABASE DEON2
USE DEON2

CREATE TABLE NHANVIEN (
    MaNV CHAR(5) PRIMARY KEY, 
    HoTen VARCHAR(20),
    NgayVL SMALLDATETIME,
    HSLuong NUMERIC(4,2),
    MaPhong CHAR(5)
);

CREATE TABLE PHONGBAN (
    MaPhong CHAR(5) PRIMARY KEY,
    TenPhong VARCHAR(25),
    TruongPhong CHAR(5)
);

CREATE TABLE XE (
    MaXe CHAR(5) PRIMARY KEY,
    LoaiXe VARCHAR(20),
    SoChoNgoi INT,
    NamSX INT
);

CREATE TABLE PHANCONG (
    MaPC CHAR(5) PRIMARY KEY,
    MaNV CHAR(5),
    MaXe CHAR(5),
    NgayDi SMALLDATETIME,
    NgayVe SMALLDATETIME,
    NoiDen VARCHAR(25),
    FOREIGN KEY (MaNV) REFERENCES NHANVIEN(MaNV),
    FOREIGN KEY (MaXe) REFERENCES XE(MaXe)
);

--2. Hiện thực các ràng buộc toàn vẹn sau:  
--2.1. Năm sản xuất của xe loại Toyota phải từ năm 2006 trở về sau. (1.5 đ)  
ALTER TABLE XE
ADD CONSTRAINT CK_NamSX_Toyota
CHECK (
    (LoaiXe <> 'Toyota') OR (LoaiXe = 'Toyota' AND NamSX >= 2006)
);
--2.2. Nhân viên thuộc phòng lái xe “Ngoại thành” chỉ được phân công lái xe loại Toyota. (1.5 đ)  
GO
CREATE TRIGGER trg_CheckLoaiXeNgoaiThanh
ON PHANCONG
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted pc
        JOIN NHANVIEN nv ON pc.MaNV = nv.MaNV
        JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
        JOIN XE xe ON pc.MaXe = xe.MaXe
        WHERE pb.TenPhong = N'Ngoại thành' AND xe.LoaiXe <> N'Toyota'
    )
    BEGIN
        RAISERROR ('Nhân viên phòng "Ngoại thành" chỉ được lái xe loại Toyota.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
--3. Viết các câu lệnh SQL thực hiện các câu truy vấn sau:  
--3.1. Tìm nhân viên (MaNV,HoTen) thuộc phòng lái xe “Nội thành” được phân công lái 
--loại xe Toyota có số chỗ ngồi là 4. (1.5 đ)  
SELECT DISTINCT nv.MaNV, nv.HoTen
FROM NHANVIEN nv
JOIN PHONGBAN pb ON nv.MaPhong = pb.MaPhong
JOIN PHANCONG pc ON nv.MaNV = pc.MaNV
JOIN XE xe ON pc.MaXe = xe.MaXe
WHERE pb.TenPhong = N'Nội thành'
AND xe.LoaiXe = N'Toyota'
AND xe.SoChoNgoi = 4;
--3.2. Tìm nhân viên(MANV,HoTen) là trưởng phòng được phân công lái tất cả các loại xe. (1.5 đ)  
SELECT nv.MaNV, nv.HoTen
FROM NHANVIEN nv
JOIN PHONGBAN pb ON nv.MaNV = pb.TruongPhong
WHERE NOT EXISTS (
    SELECT xe.LoaiXe
    FROM XE xe
    WHERE NOT EXISTS (
        SELECT 1
        FROM PHANCONG pc
        WHERE pc.MaNV = nv.MaNV AND pc.MaXe = xe.MaXe
    )
);
--3.3. Trong mỗi phòng ban,tìm nhân viên (MaNV,HoTen) được phân công lái ít nhất loại xe Toyota. (1 đ) 
WITH SoLuongToyota AS (
    SELECT nv.MaNV, nv.HoTen, nv.MaPhong, COUNT(*) AS SoLanLaiToyota
    FROM NHANVIEN nv
    JOIN PHANCONG pc ON nv.MaNV = pc.MaNV
    JOIN XE xe ON pc.MaXe = xe.MaXe
    WHERE xe.LoaiXe = N'Toyota'
    GROUP BY nv.MaNV, nv.HoTen, nv.MaPhong
)
SELECT MaPhong, MaNV, HoTen, SoLanLaiToyota
FROM SoLuongToyota t1
WHERE SoLanLaiToyota = (
    SELECT MIN(SoLanLaiToyota)
    FROM SoLuongToyota t2
    WHERE t1.MaPhong = t2.MaPhong
);