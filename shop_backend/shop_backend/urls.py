from django.urls import path
from myapp.views import (UserRegistrationView,UserLoginView,ProductListView,OrderManagementView,
                        UserProfileView,SendVerificationCodeView,PasswordResetView)
from rest_framework_simplejwt.views import TokenRefreshView, TokenVerifyView

urlpatterns = [
    path('api/orders/', OrderManagementView.as_view(), name='orders'),
    path('api/user/info', UserProfileView.as_view(), name='user_info'),
    path('api/user/update_name/', UserProfileView.as_view(), name='update_username'),
    path('api/register/', UserRegistrationView.as_view(), name='register'),
    path('api/login/', UserLoginView.as_view(), name='login'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/token/verify/', TokenVerifyView.as_view(), name='token_verify'),
    path('api/products/', ProductListView.as_view(), name='products'),
    path('api/send_verification_code/',SendVerificationCodeView.as_view(),name='send_verification_code'),
    path('api/reset_password/',PasswordResetView.as_view(),name='reset_password'),
    path('api/orders/<int:order_id>/cancel/', OrderManagementView.as_view(), name='orders_cancel'),
]
