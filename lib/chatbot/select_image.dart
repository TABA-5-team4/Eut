import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'chat1.dart';
import 'edit_image_page.dart';
import 'image_item.dart';
import 'create_image_page.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SelectImagePage extends StatefulWidget {
  @override
  _SelectImagePageState createState() => _SelectImagePageState();
}

class _SelectImagePageState extends State<SelectImagePage> {
  List<ImageItem> imageItems = [
    ImageItem(imagePath: 'assets/botboy.png', name: '김영희'),
    ImageItem(imagePath: 'assets/image1.png', name: '김철수'),
  ];
  int? selectedIndex = 0;
  bool isEditing = false;

  void _onImageTap(int index) {
    if (!isEditing) {
      setState(() {
        selectedIndex = index;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RippleEffectPage(
            imagePath: imageItems[index].imagePath,
          ),
        ),
      );
    }
  }

  void _onEditIconTap(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditImagePage(
          imageItems: imageItems,
          initialIndex: index,
        ),
      ),
    );
  }

  void _onAddButtonTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateImagePage(onImageCreated: (newImageItem) {
          setState(() {
            imageItems.add(newImageItem);
          });
        }),
      ),
    );
  }

  void _onDeleteIconTap(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('정말로 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  imageItems.removeAt(index);
                  if (selectedIndex == index && imageItems.isNotEmpty) {
                    selectedIndex = index == imageItems.length ? index - 1 : index;
                  } else if (imageItems.isEmpty) {
                    selectedIndex = null;
                  }
                });
                Navigator.of(context).pop();
              },
              child: Text('삭제'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageItem(int index) {
    return GestureDetector(
      onTap: () => _onImageTap(index),
      child: Stack(
        children: [
          Container(
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: isEditing
                  ? Colors.grey[200]
                  : (selectedIndex == index)
                  ? Colors.pink[50]
                  : Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Opacity(
                opacity: isEditing ? 0.3 : 1.0,
                child: Image.asset(
                  imageItems[index].imagePath,
                  width: 150,
                  height: 150,
                ),
              ),
            ),
          ),
          if (isEditing)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _onDeleteIconTap(index),
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ),
          if (isEditing)
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: () => _onEditIconTap(index),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.edit,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          if (!isEditing && selectedIndex == index)
            Positioned(
              top: 8,
              right: 8,
              child: Icon(
                Icons.check_circle,
                color: Colors.red,
              ),
            ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              imageItems[index].name,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _onAddButtonTap,
      child: Container(
        margin: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Icon(
            Icons.add,
            size: 50,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          flexibleSpace: Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Align(
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Chat1(),
                            ),
                          );
                        },
                        child: SvgPicture.asset(
                            'assets/icon_eut.svg', height: 80),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    icon: Icon(isEditing ? Icons.check : Icons.edit),
                    label: Text(isEditing ? '완료' : '수정하기',
                        style: TextStyle(color: Colors.black)),
                    onPressed: () {
                      setState(() {
                        isEditing = !isEditing;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ResponsiveBuilder(
          builder: (context, sizingInformation) {
            return GridView.count(
              crossAxisCount: sizingInformation.deviceScreenType ==
                  DeviceScreenType.mobile ? 2 : 4,
              children: List.generate(
                  isEditing ? imageItems.length : imageItems.length + 1,
                      (index) {
                    if (index < imageItems.length) {
                      return _buildImageItem(index);
                    } else {
                      return _buildAddButton();
                    }
                  }
              ),
            );
          },
        ),
      ),
    );
  }
}

// sizingInformation.deviceScreenType 을 사용해 화면 크기에 따라 'crossAxisCount' 값을 조정하여
// 이미지 그리드가 모바일 장치에서는 2열, 태블릿 및 데스크탑 장치에서는 4열로 표시되도록 설정