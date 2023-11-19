import React from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import i18n from "i18next";
import { useTranslation } from "react-i18next";


export const renderSugar = () => {
    const { t } = useTranslation('translation')
    console.log("Sugar render")

    i18n.addResource('gb', 'translation', 'sugar', 'Sugar');
    i18n.addResource('de', 'translation', 'sugar', 'Zucker');
    i18n.addResource('pl', 'translation', 'sugar', 'Cukier');

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
            <Toolbar>
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('sugar')}
                </Typography>
            </Toolbar>
        </Container>
        </AppBar>
    )
}