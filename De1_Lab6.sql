CREATE DATABASE DEON1
USE DEON1

CREATE TABLE TACGIA(
MaTG Varchar(40) PRIMARY KEY,
HoTen NVarchar(40),
DiaChi NVarchar(100),
SoDT decimal(10,2),
NgSinh smalldatetime
)

CREATE TABLE SACH(
MaSach Varchar(40) PRIMARY KEY,
TenSach NVarchar(40),
TheLoai NVarChar(40)
)

CREATE TABLE TACGIA_SACH(
MaTG Varchar(40),
MaSach Varchar(40)
PRIMARY KEY(MaTG, MaSach),
FOREIGN KEY (MaTG) REFERENCES TACGIA(MaTG),
FOREIGN KEY (MaSach) REFERENCES SACH(MaSach)
)

CREATE TABLE PHATHANH(
MaPH Varchar(40) PRIMARY KEY,
MaSach Varchar(40),
NgayPH smalldatetime,
SoLuong int,
NhaXuatBan NVarchar(100)
FOREIGN KEY (MaSach) REFERENCES SACH(MaSach)
)

--2. Hiện thực các ràng buộc toàn vẹn sau:  
--2.1. Ngày phát hành sách phải lớn hơn ngày sinh của tác giả. (1.5 đ) 
GO
CREATE TRIGGER trg_CheckNgayPH ON PHATHANH
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN TACGIA_SACH ts ON i.MaSach = ts.MaSach
        JOIN TACGIA tg ON ts.MaTG = tg.MaTG
        WHERE i.NgayPH <= tg.NgSinh
    )
    BEGIN
        RAISERROR ('Ngày phát hành phải lớn hơn ngày sinh của tác giả!', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

--2.2. Sách thuộc thể loại “Giáo khoa” chỉ do nhà xuất bản “Giáo dục” phát hành. (1.5 đ)  
GO
CREATE TRIGGER trg_CheckTheLoaiNXB
ON PHATHANH
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN SACH s ON i.MaSach = s.MaSach
        WHERE s.TheLoai = N'Giáo khoa' AND i.NhaXuatBan <> N'Giáo dục'
    )
    BEGIN
        RAISERROR ('Sách thể loại "Giáo khoa" chỉ được phát hành bởi nhà xuất bản "Giáo dục".', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

--3. Viết các câu lệnh SQL thực hiện các câu truy vấn sau:  
--3.1. Tìm tác giả (MaTG,HoTen,SoDT) của những quyển sách thuộc thể loại “Văn học” 
--do nhà xuất bản Trẻ phát hành. (1.5 đ)  
SELECT DISTINCT tg.MaTG, tg.HoTen, tg.SoDT
FROM TACGIA tg
JOIN TACGIA_SACH ts ON tg.MaTG = ts.MaTG
JOIN SACH s ON ts.MaSach = s.MaSach
JOIN PHATHANH ph ON s.MaSach = ph.MaSach
WHERE s.TheLoai = N'Văn học' AND ph.NhaXuatBan = N'Trẻ';
--3.2. Tìm nhà xuất bản phát hành nhiều thể loại sách nhất.(1.5 đ) 
SELECT TOP 1 ph.NhaXuatBan, COUNT(DISTINCT s.TheLoai) AS SoTheLoai
FROM PHATHANH ph
JOIN SACH s ON ph.MaSach = s.MaSach
GROUP BY ph.NhaXuatBan
ORDER BY SoTheLoai DESC;
--3.3. Trong mỗi nhà xuất bản, tìm tác giả (MaTG,HoTen) có số lần phát hành nhiều sách 
--nhất. (1 đ) 
WITH TacGia_NXB AS (
    SELECT ph.NhaXuatBan, tg.MaTG, tg.HoTen, COUNT(*) AS SoLanPhatHanh
    FROM PHATHANH ph
    JOIN SACH s ON ph.MaSach = s.MaSach
    JOIN TACGIA_SACH ts ON s.MaSach = ts.MaSach
    JOIN TACGIA tg ON ts.MaTG = tg.MaTG
    GROUP BY ph.NhaXuatBan, tg.MaTG, tg.HoTen
)
SELECT NhaXuatBan, MaTG, HoTen, SoLanPhatHanh
FROM TacGia_NXB t1
WHERE SoLanPhatHanh = (
    SELECT MAX(SoLanPhatHanh)
    FROM TacGia_NXB t2
    WHERE t1.NhaXuatBan = t2.NhaXuatBan
);