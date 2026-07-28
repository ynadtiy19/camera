import 'api_exception.dart';

/// 统一网络响应数据结构解析
class ApiResponse<T> {
  final int count;
  final int respCode; // 保存业务状态码 (支持 code 或 resp_code)
  final String respMsg; // 保存业务提示文本 (支持 msg 或 resp_msg)
  final T? datas; // 业务数据主体 (支持 data 或 datas)

  ApiResponse({
    required this.count,
    required this.respCode,
    required this.respMsg,
    this.datas,
  });

  /// 自动解析 JSON，支持泛型提取与多套后端字段名兼容
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    // 兼容新接口的 code (200) 以及旧接口的 resp_code (0)
    int code = -1;
    if (json.containsKey('code')) {
      code = json['code'] is int
          ? json['code']
          : int.tryParse(json['code'].toString()) ?? -1;
    } else if (json.containsKey('resp_code')) {
      code = json['resp_code'] is int
          ? json['resp_code']
          : int.tryParse(json['resp_code'].toString()) ?? -1;
    }

    // 兼容新接口的 msg 以及旧接口的 resp_msg
    String msg = '消息未返回';
    if (json.containsKey('msg') && json['msg'] != null) {
      msg = json['msg'].toString();
    } else if (json.containsKey('resp_msg') && json['resp_msg'] != null) {
      msg = json['resp_msg'].toString();
    } else if (json.containsKey('message') && json['message'] != null) {
      msg = json['message'].toString();
    }

    // 兼容新接口的 data 以及旧接口的 datas
    dynamic dataBody;
    if (json.containsKey('data')) {
      dataBody = json['data'];
    } else if (json.containsKey('datas')) {
      dataBody = json['datas'];
    }

    return ApiResponse(
      count: json['count'] ?? 0,
      respCode: code,
      respMsg: msg,
      datas: dataBody as T?,
    );
  }

  /// 业务是否成功判定 (code == 200 或 resp_code == 0 均视为成功)
  bool get isSuccess => respCode == 200 || respCode == 0;

  /// 如果业务失败，抛出业务异常
  void checkBusinessError() {
    if (!isSuccess) {
      throw ApiException(
        statusCode: 200,
        businessCode: respCode,
        message: respMsg,
      );
    }
  }
}
